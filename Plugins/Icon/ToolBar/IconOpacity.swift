import MagicCore
import SwiftUI

struct IconOpacity: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State var icon: IconModel?
    @State var opacity: Double = 1

    var body: some View {
        VStack {
            if icon != nil {
                Slider(value: $opacity, in: 0 ... 1)
                    .padding()
            }
        }
        .padding()
        .onAppear(perform: reloadData)
        .onChange(of: opacity, updateOpacity)
        .onChange(of: self.i.iconURL, reloadData)
    }

    private func reloadData() {
        self.icon = try? i.getIcon()
        self.opacity = self.icon?.opacity ?? 1.0
    }

    private func updateOpacity() {
        if var icon = try? self.i.getIcon() {
            try? icon.updateOpacity(opacity)
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
