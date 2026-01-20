/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that allows a person to configure the size of their drawing canvas.
*/

import SwiftUI
import RealityKit

struct DrawingCanvasConfigurationView: View {
    @Bindable var settings: DrawingCanvasSettings

    @MainActor @State var placementResetPose: Entity?
    
    @Environment(\.setMode) var setMode
    @Environment(\.physicalMetrics) var physicalMetrics
    
    private let resetPose = Entity()

    private func resetPlacement(duration: TimeInterval = 0.2) {
        if let resetPoseMatrix = placementResetPose?.transformMatrix(relativeTo: .immersiveSpace) {
            var transform = Transform(matrix: resetPoseMatrix)
            transform.scale = .one
            settings.placementEntity.move(to: transform, relativeTo: nil, duration: duration)
            settings.placementEntity.isEnabled = true
        }
    }

    private var isPlacementLockedToWindow: Bool {
        if !settings.placementEntity.isEnabled {
            return true
        } else if let component = settings.placementEntity.components[DrawingCanvasPlacementComponent.self] {
            return component.lockedToWindow
        }
        return false
    }

    var body: some View {
        VStack {
            Spacer(minLength: 20)

            Text("Setup Canvas").font(.title)

            Spacer(minLength: 10)

            RealityView { content in
                resetPose.position.x = 0.2
                content.add(resetPose)
                
                placementResetPose = resetPose
                settings.placementEntity.isEnabled = false
                
                resetPlacement()
            } update: { content in
                if isPlacementLockedToWindow {
                    resetPlacement()
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(0.5))
                if isPlacementLockedToWindow {
                    resetPlacement()
                }
                
                // 1.5 METER radius
                if settings.radius < 1.5 {
                    settings.radius = 1.5
                }
            }
            .frame(depth: 0).frame(width: 0, height: 0)
                    
            Spacer(minLength: 20)

            Button("Reset Position") {
                resetPlacement()
            }

            Spacer(minLength: 20)

            HStack {
                Text("Size")
                //  adjusting the scale to allow it to be significantly bigger
                Slider(value: $settings.radius, in: 0.5...4.0)
            }

            Spacer(minLength: 40)

            Button("Start Drawing") {
                Task { await setMode(.drawing) }
            }
            .buttonStyle(.borderedProminent)

            Spacer(minLength: 20)
        }
        .padding(20)
        .frame(width: 300, height: 300)
    }
}
