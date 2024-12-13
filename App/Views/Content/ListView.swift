import SwiftUI

struct ListView: View {
    @EnvironmentObject var p: PluginProvider
    @EnvironmentObject var a: AppProvider

    var tabPlugins: [SuperPlugin] {
        p.plugins.filter { $0.isTab }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                tabPlugins.first { $0.label == a.currentTab }?.addListView()
            }.frame(maxHeight: .infinity)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
