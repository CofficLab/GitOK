import SwiftUI
import LumiUI

/// 根布局内容区（可选带右侧 trailing pane）。
///
/// 布局规则：
/// - 当 trailing pane 可见且有主内容时，面板以**覆盖式浮层**盖在内容区上方：
///   右侧对齐，整体往右偏移（`paneRevealWidth`），露出内容区左侧一小块；
///   面板左上角带返回按钮，点击后收起面板（`isVisible = false`）。
/// - 无主内容（contentView 为 nil，如 ChatPanel 激活时）时面板独占整个内容区。
@MainActor
struct RootMainContentView: View {
    @LumiTheme private var theme
    let contentHeaderView: AnyView?
    let isContentHeaderViewHidden: Bool
    let contentView: AnyView?
    let contentFooterView: AnyView?
    let isContentFooterViewHidden: Bool
    let contentFooterHeight: ContentFooterHeight
    let onContentFooterResize: (@MainActor (CGFloat) -> Void)?
    let isContentViewHidden: Bool
    @ObservedObject var trailingPane: RootTrailingPane
    init(
        contentHeaderView: AnyView?,
        isContentHeaderViewHidden: Bool,
        contentView: AnyView?,
        contentFooterView: AnyView?,
        isContentFooterViewHidden: Bool = false,
        contentFooterHeight: ContentFooterHeight = .standard,
        onContentFooterResize: (@MainActor (CGFloat) -> Void)? = nil,
        isContentViewHidden: Bool,
        trailingPane: RootTrailingPane?
    ) {
        self.contentHeaderView = contentHeaderView
        self.isContentHeaderViewHidden = isContentHeaderViewHidden
        self.contentView = contentView
        self.contentFooterView = contentFooterView
        self.isContentFooterViewHidden = isContentFooterViewHidden
        self.contentFooterHeight = contentFooterHeight
        self.onContentFooterResize = onContentFooterResize
        self.isContentViewHidden = isContentViewHidden
        _trailingPane = ObservedObject(wrappedValue: trailingPane ?? RootTrailingPane(
            id: "root.empty",
            isVisible: false,
            content: AnyView(EmptyView())
        ))
    }

    private var mainContent: some View {
        (contentView ?? AnyView(ContentPlaceholderView()))
            .debugBlockBadge("内容区", alignment: .bottomTrailing)
    }

    /// 右侧面板（trailing pane）内容，右下角叠加区块名 badge。
    private var trailingPaneContent: some View {
        trailingPane.content
            .debugBlockBadge("右侧面板", alignment: .bottomTrailing)
    }

    /// 覆盖式布局下内容区左侧需要露出的宽度（面板整体往右偏移的量）。
    private var paneRevealWidth: CGFloat { 48 }

    /// 覆盖式浮层面板宽度：占满内容区宽度，仅左侧露出 `paneRevealWidth`。
    ///
    /// 内容区过窄时回退到面板 `minWidth`（最多占满整个内容区）。
    private func paneWidth(containerWidth: CGFloat) -> CGFloat {
        let revealedWidth = containerWidth - paneRevealWidth
        return min(containerWidth, max(trailingPane.minWidth, revealedWidth))
    }

    /// 覆盖式浮层面板：面板内容 + 左边缘分隔线 + 左上角返回按钮 + 投影。
    private func floatingTrailingPane(containerWidth: CGFloat) -> some View {
        trailingPaneContent
            .frame(width: paneWidth(containerWidth: containerWidth), maxHeight: .infinity)
            .background(theme.surface)
            .overlay(alignment: .leading) {
                // 左边缘分隔线：区分浮层与下方露出的内容区。
                Rectangle()
                    .fill(theme.divider)
                    .frame(width: 1)
            }
            .overlay(alignment: .topLeading) {
                dismissTrailingPaneButton
                    .padding(8)
            }
            .shadow(color: .black.opacity(0.14), radius: 10, x: -3, y: 0)
    }

    /// 面板左上角的返回按钮：点击后收起右侧面板。
    private var dismissTrailingPaneButton: some View {
        AppIconButton(systemImage: "chevron.left", size: .regular) {
            withAnimation(.easeInOut(duration: 0.22)) {
                trailingPane.isVisible = false
            }
        }
        .help("收起右侧面板")
    }

    @ViewBuilder
    private var contentWithHeaderAndFooter: some View {
        if let contentFooterView, !isContentFooterViewHidden {
            #if os(macOS)
            VSplitView {
                contentWithHeader
                    .frame(minHeight: 0, maxHeight: .infinity)
                    .appSplitDivider(
                        .bottom,
                        initialTrailingSize: contentFooterHeight.idealHeight,
                        resizeTarget: .trailing,
                        onResize: onContentFooterResize
                    )
                contentFooterView
                    .frame(
                        minHeight: contentFooterHeight.minHeight,
                        idealHeight: contentFooterHeight.idealHeight,
                        maxHeight: contentFooterHeight.maxHeight
                    )
                    .zIndex(1)
                    .debugBlockBadge("Footer")
            }
            #else
            VStack(spacing: 0) {
                contentWithHeader
                contentFooterView
            }
            #endif
        } else if contentHeaderView != nil && !isContentHeaderViewHidden {
            contentWithHeader
        } else {
            mainContent
        }
    }

    @ViewBuilder
    private var contentWithHeader: some View {
        VStack(spacing: 0) {
            if let contentHeaderView, !isContentHeaderViewHidden {
                contentHeaderView
                    .debugBlockBadge("Header")
                    .zIndex(1)
            }
            mainContent
                // AppKit-backed editors can draw floating subviews (for example,
                // the line-number gutter) outside their SwiftUI layout bounds.
                // Keep those subviews below the fixed content header while scrolling.
                .clipped()
        }
    }

    /// 是否存在有意义的主内容（header 或 content 任一被注入）。
    ///
    /// 当入口不需要独立的主内容区时（如 ChatPanel，激活时 `contentView` 被置 nil），
    /// 三个插槽均为 nil，布局层据此跳过主内容区，让 trailing pane 独占。
    private var hasMainContent: Bool {
        (contentHeaderView != nil && !isContentHeaderViewHidden)
            || contentView != nil
            || (contentFooterView != nil && !isContentFooterViewHidden)
    }

    var body: some View {
        Group {
            if isContentViewHidden {
                // 主内容区被完全隐藏（如 ChatPanel 调用 setContentViewHidden(true)）：
                // 不渲染内容区，trailing pane 独占全部空间。
                if trailingPane.isVisible {
                    trailingPaneContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if trailingPane.isVisible {
                if hasMainContent {
                    // 覆盖式浮层面板：盖在内容区上方、右侧对齐，整体往右偏移
                    // `paneRevealWidth`，露出内容区左侧一小块；左上角返回按钮
                    // 点击后收起面板。
                    GeometryReader { proxy in
                        ZStack(alignment: .trailing) {
                            contentWithHeaderAndFooter
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            if trailingPane.isVisible {
                                floatingTrailingPane(containerWidth: proxy.size.width)
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                    .zIndex(1)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.22), value: trailingPane.isVisible)
                } else {
                    // 无主内容（contentView 为 nil）：trailing pane 独占，不渲染占位视图
                    trailingPaneContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                contentWithHeaderAndFooter
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
