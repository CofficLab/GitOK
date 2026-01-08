import SwiftUI
import MagicUI

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
        .labelStyle(.iconOnly)
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background(MagicBackground.desert.opacity(0.3))
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
