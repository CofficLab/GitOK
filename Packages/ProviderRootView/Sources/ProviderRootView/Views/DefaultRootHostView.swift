import Foundation
import LumiUI
import SwiftUI

@MainActor
struct DefaultRootHostView: View {
    @ObservedObject var provider: DefaultRootViewProvider
    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference

    var body: some View {
        VStack(spacing: 0) {
            if let toolbarView = provider.toolbarView {
                toolbarView
                    .debugBlockBadge(LumiPluginLocalization.string("Toolbar", bundle: .module), alignment: .bottomLeading)
                // 与旧版 AppLayoutView 一致：工具栏下方使用主题分隔线。
                AppDivider()
            }

            Group {
                #if os(macOS)
                if let sidebarView = provider.sidebarView, !provider.isSidebarViewHidden {
                    HSplitView {
                        sidebarView
                            .frame(
                                minWidth: provider.sidebarWidth.minWidth,
                                idealWidth: provider.sidebarWidth.idealWidth,
                                maxWidth: provider.sidebarWidth.maxWidth
                            )
                            .appSplitDivider(
                                .trailing,
                                initialPosition: provider.sidebarWidth.idealWidth,
                                onResize: provider.saveSidebarWidth
                            )
                            .debugBlockBadge(LumiPluginLocalization.string("Sidebar", bundle: .module), alignment: .bottomLeading)
                            .transition(sidebarTransition)
                        WorkbenchSplitView(provider: provider)
                    }
                } else {
                    WorkbenchSplitView(provider: provider)
                }
                #else
                HStack(spacing: 0) {
                    if let sidebarView = provider.sidebarView, !provider.isSidebarViewHidden {
                        sidebarView
                            .debugBlockBadge(LumiPluginLocalization.string("Sidebar", bundle: .module), alignment: .bottomLeading)
                            .transition(sidebarTransition)
                    }

                    WorkbenchSplitView(provider: provider)
                }
                #endif
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // 侧边栏显隐跟随工具栏按钮切换：沿左边缘滑入/滑出并伴随淡入/淡出，
            // 主内容区同步平滑扩展/收缩；遵循减少动效偏好时退化为瞬时切换。
            .animation(
                LumiMotion.enabled(LumiMotion.disclosure, preference: motionPreference),
                value: provider.isSidebarViewHidden
            )

            // 窗口底部状态栏（工具栏的对称位置）。
            if let statusBarView = provider.statusBarView {
                statusBarView
                    .debugBlockBadge(LumiPluginLocalization.string("Status Bar", bundle: .module))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .appThemedAppearance()
        #if os(macOS)
        .background {
            ThemeWindowAppearanceBridge()
        }
        #endif
        .environmentObject(AppThemeVM.shared)
        #if os(macOS)
            .ignoresSafeArea()
        #endif
    }

    /// 侧边栏显隐过渡：沿左边缘滑入/滑出并叠加透明度变化。
    private var sidebarTransition: AnyTransition {
        .move(edge: .leading).combined(with: .opacity)
    }
}
