/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Views that control the settings selection on the palette for each style of brush.
*/

import SwiftUI
import RealityKit

struct SparkleBrushStyleView: View {
    @Binding var settings: SparkleBrushStyleProvider.Settings

    var body: some View {
        VStack {
            ColorPicker("Color", selection: Color.makeBinding(from: $settings.color))
            
            HStack {
                Text("Thickness")
                Slider(value: $settings.initialSpeed, in: 0.005...0.02)
                    .transaction { $0.animation = nil }
            }
            
            HStack {
                Text("Particle Size")
                Slider(value: $settings.size, in: 0.000_15...0.000_35)
                    .transaction { $0.animation = nil }
            }
        }
    }
}

struct BrushTypeView: View {
    @Binding var brushState: BrushState

    var body: some View {
        VStack {
            Text(BrushType.sparkle.label).tag(BrushType.sparkle)

            ScrollView(.vertical) {
                ZStack {
                    SparkleBrushStyleView(settings: $brushState.sparkleStyleSettings)
                        .id("BrushStyleView")
                }
                .animation(.easeInOut, value: brushState.brushType)
            }
        }
    }
}
