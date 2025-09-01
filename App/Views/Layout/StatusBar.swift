import MagicCore
import SwiftUI

struct StatusBar: View {
    @EnvironmentObject var p: PluginProvider

    var body: some View {
        HStack(spacing: 0) {
            ForEach(p.plugins, id: \.instanceLabel) { plugin in
                plugin.addStatusBarLeadingView()
            }
            Spacer()
            ForEach(p.plugins, id: \.instanceLabel) { plugin in
                plugin.addStatusBarTrailingView()
            }
        }
        .padding(.trailing, 10)
        .labelStyle(.iconOnly)
        .frame(maxWidth: .infinity)
        .background(MagicBackground.desert.opacity(0.3))
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(BannerPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(BannerPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
