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
        .padding()
        .onAppear(perform: reloadData)
        .onChange(of: scale, updateScale)
        .onChange(of: self.i.iconURL, reloadData)
    }

    private func reloadData() {
        self.icon = try? i.getIcon()
        self.scale = self.icon?.scale ?? 1.0
    }

    private func updateScale() {
        if var icon = try? self.i.getIcon() {
            try? icon.updateScale(scale)
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
