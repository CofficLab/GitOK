import SwiftUI

struct IconOpacity: View {
    @Binding var icon: IconModel
    
    var body: some View {
        VStack {
            Slider(value: $icon.opacity, in: 0 ... 1)
                .padding()
        }
        .padding()
    }
}

#Preview {
    RootView {
        Content()
    }
}
