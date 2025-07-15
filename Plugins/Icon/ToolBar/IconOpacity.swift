import SwiftUI
import MagicCore

struct IconOpacity: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State var icon: IconModel?
    
    var body: some View {
        VStack {
            if icon != nil {
                Slider(value: Binding(
                    get: { self.icon?.opacity ?? 1.0 },
                    set: { newOpacity in
                        if self.icon != nil {
                            do {
                                try self.icon!.updateOpacity(newOpacity)
                            } catch {
                                m.error(error.localizedDescription)
                            }
                        }
                    }
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
