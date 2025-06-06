import SwiftUI

struct Tabs: View {
    @EnvironmentObject var p: PluginProvider

    @Binding var tab: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(p.plugins, id: \.label) { plugin in
                    plugin.addListView(tab: tab)
                }
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
