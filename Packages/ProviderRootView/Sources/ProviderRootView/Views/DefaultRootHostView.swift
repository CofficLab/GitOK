import Foundation
import LumiUI
import SwiftUI

@MainActor
struct DefaultRootHostView: View {
    @ObservedObject var provider: DefaultRootViewProvider
    @LumiTheme private var theme

    var body: some View {
        VStack(spacing: 0) {
            if let toolbarView = provider.toolbarView {
                toolbarView
                    .debugBlockBadge("工具栏", alignment: .bottomLeading)
                // 与旧版 AppLayoutView 一致：工具栏下方使用主题分隔线。
                AppDivider()
            }

            HStack(spacing: 0) {
                if let sidebarView = provider.sidebarView, !provider.isSidebarViewHidden {
                    sidebarView
                        .debugBlockBadge("侧边栏", alignment: .bottomLeading)
                }

                WorkbenchSplitView(provider: provider)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 窗口底部状态栏（工具栏的对称位置）。
            if let statusBarView = provider.statusBarView {
                statusBarView
                    .debugBlockBadge("状态栏")
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
}
