import SwiftUI
import MagicCore

/**
 * Banner背景纯显示组件
 * 只负责显示背景，不包含任何编辑功能
 * 数据变化时自动重新渲染
 */
struct BannerBackground: View {
    @EnvironmentObject var b: BannerProvider

    var body: some View {
        MagicBackgroundGroup(for: b.banner.backgroundId)
            .opacity(b.banner.opacity)
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
