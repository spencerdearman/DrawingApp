/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that encapsulates the palette functionality, including settings and preset selectors.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct PaletteView: View {
    @Binding var brushState: BrushState
    @Binding var immersionStyle: ImmersionStyle

    @State var isDrawing: Bool = false
    @State var isSettingsPopoverPresented: Bool = false

    var body: some View {
        VStack {
            HStack {
                Text("Palette")
                    .font(.title)
                    .padding()
            }
            
            Picker("Immersion Style", selection: Binding<UIImmersionStyle>(
                get: {
                    // Convert the existential ImmersionStyle to our local enum
                    // Assuming .mixed and .full are the primary types we care about
                    let description = String(describing: immersionStyle)
                    if description.contains("Progressive") {
                        return .progressive
                    } else {
                        return .mixed
                    }
                },
                set: { newValue in
                    switch newValue {
                    case .mixed:
                        immersionStyle = .mixed
                    case .progressive:
                        immersionStyle = .progressive
                    }
                }
            )) {
                Text("Passthrough").tag(UIImmersionStyle.mixed)
                Text("Dimmed").tag(UIImmersionStyle.progressive)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            Divider()
                .padding(.horizontal, 20)

            BrushTypeView(brushState: $brushState)
                .padding(.horizontal, 20)
        
        }
        .padding(.vertical, 20)
    }
}

enum UIImmersionStyle: String, CaseIterable, Identifiable {
    case mixed
    case progressive
    
    var id: String { rawValue }
}
