import SwiftUI
import MagicCore

/**
 * Banner功能特性纯显示组件
 * 只负责显示功能特性列表，不包含任何编辑功能
 * 数据变化时自动重新渲染
 */
struct Features: View {
    @EnvironmentObject var b: BannerProvider

    var body: some View {
        LazyHGrid(rows: [
            GridItem(.flexible(minimum: 260, maximum: 300)),
            GridItem(.flexible(minimum: 260, maximum: 300)),
        ], spacing: 50) {
            ForEach(Array(b.banner.features.enumerated()), id: \.offset) { i, featureText in
                Feature(title: featureText)
            }
        }
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
