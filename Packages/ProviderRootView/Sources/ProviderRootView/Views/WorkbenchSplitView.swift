import SwiftUI
import LumiUI

@MainActor
struct WorkbenchSplitView: View {
    @ObservedObject var provider: DefaultRootViewProvider
    @LumiTheme private var theme

    private var showsRail: Bool {
        provider.railView != nil && provider.isRailViewVisible
    }

    var body: some View {
        Group {
            if showsRail {
                #if os(macOS)
                HSplitView {
                    provider.railView!
                        .frame(
                            minWidth: provider.railWidth.minWidth,
                            idealWidth: provider.railWidth.idealWidth,
                            maxWidth: provider.railWidth.maxWidth
                        )
                        .appSplitDivider(
                            .trailing,
                            initialPosition: provider.railWidth.idealWidth,
                            onResize: provider.saveRailViewWidth
                        )
                        .debugBlockBadge("Rail")
                    (provider.hasActiveContent ? AnyView(mainContent) : AnyView(RootWelcomeView()))
                        .overlay(alignment: .leading) {
                            railTrailingDividerDecoration
                        }
                }
                #else
                HStack(spacing: 0) {
                    provider.railView!
                        .debugBlockBadge("Rail")
                    Divider()
                    provider.hasActiveContent ? AnyView(mainContent) : AnyView(RootWelcomeView())
                }
                #endif
            } else if provider.hasActiveContent {
                mainContent
            } else {
                // 与旧版 AppLayoutView 一致：无活跃内容时显示欢迎占位。
                RootWelcomeView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mainContent: some View {
        RootMainContentView(
            contentHeaderView: provider.contentHeaderView,
            isContentHeaderViewHidden: provider.isContentHeaderViewHidden,
            contentView: provider.contentView,
            contentFooterView: provider.contentFooterView,
            isContentFooterViewHidden: provider.isContentFooterViewHidden,
            contentFooterHeight: provider.contentFooterHeight,
            onContentFooterResize: provider.saveCurrentContentFooterHeight,
            isContentViewHidden: provider.isContentViewHidden,
            trailingPane: provider.trailingPane
        )
    }

    /// Draw the rail divider's matching decoration inside the content pane as
    /// well, so both sides of the split retain a visible border and shadow.
    private var railTrailingDividerDecoration: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [.black.opacity(0.04), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )

            Rectangle()
                .fill(theme.divider)
                .frame(width: 0.5)
        }
        .frame(width: 8)
        .allowsHitTesting(false)
    }
}
