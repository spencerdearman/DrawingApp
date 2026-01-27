/*
 See the LICENSE.txt file for this sample’s licensing information.
 
 Abstract:
 A compute kernel written in Metal Shading Language to simulate the particles in a Sparkle brush stroke,
 and also to populate the mesh of a sparkle brush with the result of the simulation.
 */

#include <metal_stdlib>

#include "SparkleBrushVertex.h"

using namespace metal;

[[kernel]]
void sparkleBrushPopulate(device const SparkleBrushParticle *particles [[buffer(0)]],
                          device SparkleBrushVertex *output [[buffer(1)]],
                          constant const uint32_t &particleCount [[buffer(2)]],
                          uint particleIdx [[thread_position_in_grid]])
{
    if (particleIdx >= particleCount) {
        return;
    }
    
    SparkleBrushParticle particle = particles[particleIdx];
    
    const uint startIndex = particleIdx * 4;
    output[startIndex + 0] = SparkleBrushVertex { .attributes = particle.attributes, .uv = { 0, 0 }};
    output[startIndex + 1] = SparkleBrushVertex { .attributes = particle.attributes, .uv = { 0, 1 }};
    output[startIndex + 2] = SparkleBrushVertex { .attributes = particle.attributes, .uv = { 1, 1 }};
    output[startIndex + 3] = SparkleBrushVertex { .attributes = particle.attributes, .uv = { 1, 0 }};
}

[[kernel]]
void sparkleBrushSimulate(device const SparkleBrushParticle *particles [[buffer(0)]],
                          device SparkleBrushParticle *output [[buffer(1)]],
                          constant SparkleBrushSimulationParams &params [[buffer(2)]],
                          uint particleIdx [[thread_position_in_grid]])
{
    const bool lorenzAttroctorSimulationEnabled = false;
    
    if (lorenzAttroctorSimulationEnabled) {
        // LORENZ ATTRACTOR SIMULATION
        if (particleIdx >= params.particleCount) {
            return;
        }
        
        SparkleBrushParticle particle = particles[particleIdx];
        
        // --- 0. CONFIGURATION ---
        // Change these numbers to move the "center" of the tornado.
        // x = 0.0 (Left/Right center)
        // y = 1.2 (Height in meters. 1.2 is roughly chest/eye height when sitting)
        // z = -0.5 (Depth in meters. Negative is usually "forward" away from you)
        const float3 centerOffset = float3(0.0, 1.0, -1.0);
        
        // Standard Lorenz constants
        const float sigma = 10.0;
        const float rho = 28.0;
        const float beta = 8.0 / 3.0;
        const float scaleInput = 15.0;
        const float speedFactor = 0.6;
        
        // relative position, getting the particle's ACTUAL world position
        float3 worldPos = particle.attributes.position;
        
        // Calculate position RELATIVE to our custom center.
        // This effectively moves the attractor to 'centerOffset'
        float3 relativePos = worldPos - centerOffset;
        
        // random kick
        // Generate random seed
        float2 seed = float2(float(particleIdx), params.deltaTime);
        float randomVal = fract(sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453);
        
        // If particle is too close to the center, kick it out so it starts moving
        if (length(relativePos) < 0.05) {
            // We modify the world position directly to nudge it
            particle.attributes.position += float3(randomVal - 0.5, randomVal - 0.5, randomVal - 0.5) * 0.1;
            // Recalculate relative pos after nudge
            relativePos = particle.attributes.position - centerOffset;
        }
        
        // math space, scale the relative position for the math
        float3 p = relativePos * scaleInput;
        
        // Lorenz Equations
        // Calculate forces based on 'p' (the relative position)
        float dx = sigma * (p.y - p.x);
        float dy = p.x * (rho - p.z) - p.y;
        float dz = p.x * p.y - beta * p.z;
        
        float3 lorenzForce = float3(dx, dy, dz);
        
        // update the velocity
        float3 targetVelocity = lorenzForce * speedFactor * 0.1;
        
        // smooth blending
        particle.velocity = mix(particle.velocity, targetVelocity, 0.1);
        
        // adding the randomness
        particle.velocity.x += (randomVal - 0.5) * 0.5;
        particle.velocity.y += (fract(randomVal * 10) - 0.5) * 0.5;
        particle.velocity.z += (fract(randomVal * 100) - 0.5) * 0.5;
        
        // safety
        if (length(particle.velocity) > 5.0) {
            particle.velocity = normalize(particle.velocity) * 5.0;
        }
        
        // apply the changes
        particle.attributes.position += particle.velocity * params.deltaTime;
        
        output[particleIdx] = particle;
    } else {
        // REGULAR SIMULATION
        if (particleIdx >= params.particleCount) {
            return;
        }
        
        SparkleBrushParticle particle = particles[particleIdx];
        
        const float speed2 = length_squared(particle.velocity);
        const float dragForce = -speed2 * (params.dragCoefficient * params.deltaTime);
        const float speed = sqrt(speed2);
        const float newSpeed = max(0.f, speed + dragForce);
        
        if (min(newSpeed, speed) > 0.0001) {
            particle.velocity = particle.velocity / speed * newSpeed;
        } else {
            particle.velocity = 0;
        }
        
        // calculate a random value to give each particle more personality
        float randomVal = fract(sin(float(particleIdx)) * 43758.5453);
        
        // if the random number is > 0.5, spin one way. Otherwise, spin the other.
        // This creates the "chaos" where they don't all look identical.
        float direction = (randomVal > 0.5) ? 1.0 : -1.0;
        
        // instead of a vortex, we are using a Sine wave based on how high the particle is (i.e. position.y)
        // as the particle rises, the 'sway' goes from -1 to +1 to -1. THen, we multiply the direction
        // so that half ot eh particles sway opposite to the others
        float sway = sin(particle.attributes.position.y * 10.0 + (randomVal * 5.0));
        
        // apply the sway to X, then a slgihtly different way using Cos to Z. This creates wandering, and floating.
        float strength = 2.0;
        particle.velocity.x += sway * direction * strength * params.deltaTime;
        particle.velocity.z += cos(particle.attributes.position.y * 5.0) * strength * params.deltaTime;
        
        // gentle lift upwards
        particle.velocity.y += 0.2 * params.deltaTime;
        
        // update step
        particle.attributes.position += particle.velocity * params.deltaTime;
        // ------------------
        
        // Write to output.
        output[particleIdx] = particle;
    }
}
