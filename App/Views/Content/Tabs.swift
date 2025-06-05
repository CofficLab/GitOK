import SwiftUI

struct Tabs: View {
    @EnvironmentObject var p: PluginProvider

    @Binding var tab: String

    var tabPlugins: [SuperPlugin] {
        p.plugins.filter { $0.isTab }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                tabPlugins.first { $0.label == tab }?.addListView()
            }.frame(maxHeight: .infinity)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
