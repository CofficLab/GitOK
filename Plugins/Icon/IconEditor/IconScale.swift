import SwiftUI

struct IconScale: View {
    @Binding var icon: IconModel
    
    @State var scale: Double = 1
    
    var body: some View {
        VStack {
            Slider(value: $scale, in: 0.1 ... 2)
                .padding()
        }
        .onChange(of: scale, {
            icon.scale = scale
        })
        .padding()
    }
}

#Preview {
    RootView {
        Content()
    }
    .frame(height: 800)
    .frame(width: 800)
}
