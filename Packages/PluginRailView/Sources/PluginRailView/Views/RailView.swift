import LumiUI
import SwiftUI

/// 渲染「标签栏 + 内容区」的 Rail 视图。
///
/// 视觉与旧版 `FactoryCore` 的 `RailView` + `RailTabBarView` + `RailContentView`
/// 完全一致：
/// - 顶层 `VStack(spacing: 0)`：标签栏 + 内容区（不自带分隔线，
///   分隔线由宿主的 `HSplitView` / `AppSplitDivider` 提供）；
/// - 标签栏复用 `AppToolbarContainer`（height 40、`.panel` 背景、
///   上下 8 / 左右 10 内边距）+ `AppTabBar(showText: false)`（图标式），
///   并带 `borderBottom` + `shadowMd`；仅在 tab 数量大于一个时显示；
/// - 内容区直接渲染激活 tab 视图（`.id` 保持切换动画），无内容时不渲染视图；
/// - 整栏 `minWidth 200`、背景 `theme.surface`。
struct RailView: View {
    @ObservedObject var provider: GitOKRailViewProvider
    @LumiTheme private var theme

    var body: some View {
        let visibleTabs = provider.visibleTabs

        if !provider.sections.isEmpty {
            // 多区块模式：VStack 纵向堆叠各插件贡献的 Rail 区块。
            // 区块自身决定高度策略：固定高度区块占自然高度，
            // 弹性区块（maxHeight: .infinity）填满剩余空间。
            VStack(spacing: 0) {
                ForEach(provider.sections) { section in
                    section.makeView()
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(minWidth: 200, maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.surface)
        } else if visibleTabs.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 0) {
                // 标签栏：仅在 tab 数量大于一个时显示（复刻旧版 showsTabBar）。
                if let firstTab = visibleTabs.first, visibleTabs.count > 1 {
                    AppToolbarContainer(
                        height: 40,
                        backgroundStyle: .panel,
                        padding: EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
                    ) {
                        AppTabBar(
                            tabs: visibleTabs.map {
                                AppTabBar.Tab(title: $0.title, icon: $0.systemImage, id: $0.id)
                            },
                            selectedTab: Binding(
                                get: { provider.activeTabID ?? firstTab.id },
                                set: { provider.activateTab(id: $0) }
                            ),
                            showText: false
                        )
                    }
                    .borderBottom()
                    .shadowMd()
                }

                // 内容区：激活 tab 视图；未命中时回退首个 tab。
                if let active = visibleTabs.first(where: { $0.id == provider.activeTabID }) {
                    active.makeView()
                        .id(active.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let first = visibleTabs.first {
                    first.makeView()
                        .id(first.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 200, maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.surface)
        }
    }
}
