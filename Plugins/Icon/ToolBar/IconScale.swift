import SwiftUI

struct IconScale: View {
    @EnvironmentObject var i: IconProvider
    
    @State var icon: IconModel?
    
    var body: some View {
        VStack {
            if icon != nil {
                Slider(value: Binding(
                    get: { self.icon?.scale ?? 1.0 },
                    set: { self.icon?.scale = $0 }
                ), in: 0.1 ... 2)
                    .padding()
            } else {
                Text("没有可用的图标")
            }
        }
        .onAppear {
            self.icon = try? i.getIcon()
        }
        .padding()
    }
}


#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
