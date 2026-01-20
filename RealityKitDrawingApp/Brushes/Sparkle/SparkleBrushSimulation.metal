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
    
    // ----------------------- testing -----------------------
    // adding simple gravity: pushing particles down over time
    // 9.8 is earth gravity, but usually in 3d this is too strong
    /*
     test 1: Adding a gravityStrength 1.0. was interesting because it created a falling canvas, which is
     interesting in it's own regard, but I do not think that it is the intended outcome. I want to try adding
     a possible floor, which could create a 'snowflake' effect.
     
     test 2: Adding a gravityStrength -1.0. Similar to test 1, except this time it is a rising motion (makes sense).
     
     test 3: Added a float timescale and then instead of just taking the params.deltaTime, I also multiplied it
     by the timescale, which basically will make it move in slower motion. I am guessing that speeding this up
     would also make it just move faster. It is interesting, but not necessarily what I want on it's own
     
     test 4: I tried to create a tornado type effect, but it ended up just creating a solid line. I think
     this is happening because all of the particles are syncrhonizing, and the exact same math is not making
     them go all over the place. It needs more chaos
     
     test 5: objectively beautiful. I need to adjust the mesh where you can draw, and I want to play with the
     physics of the particles a little bit more to introduce a little bit more randomness, but it is absolutely
     stunning when you can mix colors and how they shift and move around.
     
     test 6: YES YES YES YES YES. Now i need to figure out how to add an immersive black background because that
     would just make this an even better experience.
     
     */
    // ---- test 1 ----
    //    float gravityStrength = 1.0;
    //    particle.velocity.y -= gravityStrength * params.deltaTime;
    
    // ---- test 2 ----
    //    float gravityStrength = -1.0;
    //    particle.velocity.y -= gravityStrength * params.deltaTime;
    
    // ---- test 3 ----
    //    float timeScale = 0.5;
    //    particle.attributes.position += particle.velocity * (params.deltaTime * timeScale);
    
    // ---- test 4 ----
    //        get the direction from the particle to the center (ignoring height/Y)
    //        float2 centerDirection = -particle.attributes.position.xz;
    //
    //        rotate that direction 90 degrees to get a "tangent" (spin) force
    //        //    (x, y) becomes (-y, x) for a 90 degree turn
    //        float2 spinForce = float2(-centerDirection.y, centerDirection.x);
    //
    //        // 3. Add this force to the velocity
    //        //    '0.5' is the strength of the tornado.
    //        particle.velocity.x += spinForce.x * 2.0 * params.deltaTime;
    //        particle.velocity.z += spinForce.y * 2.0 * params.deltaTime;
    
    
    // ---- test 5 ----
    //    float2 posXZ = particle.attributes.position.xz;
    //    float dist = length(posXZ);
    //
    //    // It creates a unique personality for each particle based on its ID.
    //    float randomOffset = fract(sin(float(particleIdx)) * 43758.5453);
    //
    //    // Spin: The tangent vector (perpendicular to position)
    //    float2 spinDir = float2(-posXZ.y, posXZ.x);
    //    // Suction: Pull inward towards the center (0,0,0)
    //    float2 suctionDir = -posXZ;
    //
    //    // We mix the spin and suction.
    //    // We multiply by 'randomOffset' so some particles move fast, some slow.
    //    float forceStrength = 5.0 * (0.5 + 0.5 * randomOffset);
    //
    //    // Apply spin (to rotate) + suction (to keep them in a funnel)
    //    // Adjust 0.5 to change how tight the funnel is.
    //    particle.velocity.x += (spinDir.x + suctionDir.x * 0.5) * forceStrength * params.deltaTime;
    //    particle.velocity.z += (spinDir.y + suctionDir.y * 0.5) * forceStrength * params.deltaTime;
    //    particle.velocity.y += 0.8 * params.deltaTime;
    // ------------------------
    
    // ---- test 6 ----
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

