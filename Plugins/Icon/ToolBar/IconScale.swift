import SwiftUI
import MagicCore

struct IconScale: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var app: AppProvider
    
    @State var icon: IconModel?
    @State var scale: Double = 1
    
    var body: some View {
        VStack {
            if icon != nil {
                Slider(value: $scale, in: 0.1 ... 2)
                    .padding()
            }
        }
        .onAppear {
            self.icon = try? i.getIcon()
            self.scale = self.icon?.scale ?? 1.0
        }
        .onChange(of: scale) {
            if var icon = try? self.i.getIcon() {
                do {
                    try icon.updateScale(scale)
                } catch {
                    m.error(error.localizedDescription)
                }
            }
        }
        .onChange(of: self.i.iconURL) {
            self.icon = try? i.getIcon()
            self.scale = self.icon?.scale ?? 1.0
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
