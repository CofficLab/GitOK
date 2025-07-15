import SwiftUI

struct IconOpacity: View {
    @EnvironmentObject var i: IconProvider

    @State var icon: IconModel?
    
    var body: some View {
        VStack {
            if icon != nil {
                Slider(value: Binding(
                    get: { self.icon?.opacity ?? 1.0 },
                    set: { self.icon?.opacity = $0 }
                ), in: 0...1)
                    .padding()
            } else {
                Text("没有可用的图标")
            }
        }
        .padding()
        .onAppear {
            self.icon = try? i.getIcon()
        }
    }
}

#Preview {
    RootView {
        ContentLayout()
    }
}
