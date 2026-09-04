import SwiftUI
import LumiUI

#if os(macOS)
import AppKit
#endif

/// 根布局内容区（可选带右侧 trailing pane）。
///
/// 布局规则：
/// - 当 trailing pane 可见且有主内容时，面板作为上层浮层覆盖在主内容上方：
///   右侧对齐并可通过左边缘调节宽度，下层 contentview 始终保持自己的宽度。
/// - 无主内容（contentView 为 nil，如 ChatPanel 激活时）时面板独占整个内容区。
@MainActor
struct RootMainContentView: View {
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
            } else if hasMainContent {
                // 主内容保持在下层并始终占满可用宽度；右侧面板只作为上层
                // 叠层改变自身宽度，不会把宽度约束传给下方 contentview。
                ContentWithTrailingPaneOverlay(
                    content: contentWithHeaderAndFooter,
                    trailingPane: trailingPane
                )
            } else if trailingPane.isVisible {
                // 无主内容（contentView 为 nil）：trailing pane 独占，不渲染占位视图
                trailingPaneContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 无主内容且无面板：渲染占位视图（与原行为一致）
                contentWithHeaderAndFooter
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 覆盖式右侧面板浮层

/// 主内容 + 覆盖式右侧面板的组合视图。
///
/// 面板是 ZStack 中的上层视图，因此改变它的宽度不会改变下层主内容的
/// layout proposal。拖拽期间只更新上层面板的临时宽度，结束后才同步到
/// `RootTrailingPane` 和对应的持久化 provider。
@MainActor
private struct ContentWithTrailingPaneOverlay<Content: View>: View {
    let content: Content
    @ObservedObject var trailingPane: RootTrailingPane
    @LumiTheme private var theme

    #if !os(macOS)
    @State private var isResizing = false
    @State private var resizeStartWidth: CGFloat = 0
    @State private var dragWidth: CGFloat?
    #endif

    private var effectivePaneWidth: CGFloat {
        #if os(macOS)
        trailingPane.idealWidth
        #else
        let requestedWidth = dragWidth ?? trailingPane.idealWidth
        let clampedWidth = min(trailingPane.maxWidth, max(trailingPane.minWidth, requestedWidth))
        return clampedWidth
        #endif
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if trailingPane.isVisible {
                    floatingPane(containerWidth: proxy.size.width)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .zIndex(1)
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: trailingPane.isVisible)
    }

    private func floatingPane(containerWidth: CGFloat) -> some View {
        #if os(macOS)
        TrailingPaneOverlayHost(
            initialWidth: min(containerWidth, effectivePaneWidth),
            minWidth: trailingPane.minWidth,
            maxWidth: trailingPane.maxWidth,
            onResize: { width in
                trailingPane.setWidth(width)
                trailingPane.saveWidth(width)
            }
        ) {
            panelSurface
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #else
        panelSurface
            .frame(width: min(containerWidth, effectivePaneWidth))
            .frame(maxHeight: .infinity)
            .overlay(alignment: .leading) {
                resizeHandle
            }
        #endif
    }

    private var panelSurface: some View {
        trailingPane.content
            .debugBlockBadge("右侧面板", alignment: .bottomTrailing)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.surface)
            .overlay(alignment: .leading) {
                theme.divider
                    .frame(width: 1)
            }
            .overlay(alignment: .topLeading) {
                dismissButton
                    .padding(8)
            }
            .shadow(color: .black.opacity(0.14), radius: 10, x: -3, y: 0)
    }

    #if !os(macOS)
    private var resizeHandle: some View {
        Rectangle()
            .fill(theme.divider)
            .frame(width: 4)
            .contentShape(Rectangle().inset(by: -6))
            .onHover { hovering in
                #if os(macOS)
                if hovering {
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.arrow.set()
                }
                #endif
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isResizing {
                            isResizing = true
                            resizeStartWidth = trailingPane.idealWidth
                        }
                        // 左移扩大面板，右移缩小面板；下层 content 的宽度不参与计算。
                        dragWidth = resizeStartWidth - value.translation.width
                    }
                    .onEnded { _ in
                        guard let dragWidth else {
                            isResizing = false
                            return
                        }

                        trailingPane.setWidth(dragWidth)
                        trailingPane.saveWidth(dragWidth)
                        self.dragWidth = nil
                        isResizing = false
                    }
            )
    }
    #endif

    private var dismissButton: some View {
        AppIconButton(systemImage: "chevron.left", size: .regular) {
            withAnimation(.easeInOut(duration: 0.22)) {
                trailingPane.isVisible = false
            }
        }
        .help("收起右侧面板")
    }
}

#if os(macOS)
/// macOS 原生承载的覆盖面板。
///
/// 面板宽度和 resize handle 在 AppKit 中直接变化，拖拽过程中不回写 SwiftUI
/// 状态，也不改变下层 content 的 layout。拖拽结束后只提交一次最终宽度。
private struct TrailingPaneOverlayHost<Content: View>: NSViewRepresentable {
    let initialWidth: CGFloat
    let minWidth: CGFloat
    let maxWidth: CGFloat
    let onResize: @MainActor (CGFloat) -> Void
    let content: Content

    init(
        initialWidth: CGFloat,
        minWidth: CGFloat,
        maxWidth: CGFloat,
        onResize: @escaping @MainActor (CGFloat) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.initialWidth = initialWidth
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.onResize = onResize
        self.content = content()
    }

    func makeNSView(context: Context) -> TrailingPaneOverlayContainer<Content> {
        TrailingPaneOverlayContainer(
            rootView: content,
            initialWidth: initialWidth,
            minWidth: minWidth,
            maxWidth: maxWidth,
            onResize: onResize
        )
    }

    func updateNSView(
        _ nsView: TrailingPaneOverlayContainer<Content>,
        context: Context
    ) {
        nsView.update(
            rootView: content,
            initialWidth: initialWidth,
            minWidth: minWidth,
            maxWidth: maxWidth,
            onResize: onResize
        )
    }
}

@MainActor
private final class TrailingPaneOverlayContainer<Content: View>: NSView {
    private let hostingView: NSHostingView<Content>
    private let resizeHandle = TrailingPaneResizeHandle()
    private var panelWidth: CGFloat
    private var minWidth: CGFloat
    private var maxWidth: CGFloat
    private var onResize: @MainActor (CGFloat) -> Void
    private var isDragging = false
    private var dragStartX: CGFloat = 0
    private var dragStartWidth: CGFloat = 0
    private var pendingRootView: Content?

    init(
        rootView: Content,
        initialWidth: CGFloat,
        minWidth: CGFloat,
        maxWidth: CGFloat,
        onResize: @escaping @MainActor (CGFloat) -> Void
    ) {
        hostingView = NSHostingView(rootView: rootView)
        panelWidth = initialWidth
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.onResize = onResize
        super.init(frame: .zero)

        autoresizesSubviews = false
        wantsLayer = true
        layer?.masksToBounds = false

        resizeHandle.onMouseDown = { [weak self] event in
            self?.beginResize(with: event)
        }
        resizeHandle.onMouseDragged = { [weak self] event in
            self?.continueResize(with: event)
        }
        resizeHandle.onMouseUp = { [weak self] in
            self?.endResize()
        }

        addSubview(hostingView)
        addSubview(resizeHandle)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    override func layout() {
        super.layout()
        guard !isDragging else { return }
        layoutPanel()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard hostingView.frame.contains(point) || resizeHandle.frame.contains(point) else {
            return nil
        }
        return super.hitTest(point)
    }

    func update(
        rootView: Content,
        initialWidth: CGFloat,
        minWidth: CGFloat,
        maxWidth: CGFloat,
        onResize: @escaping @MainActor (CGFloat) -> Void
    ) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.onResize = onResize

        if isDragging {
            pendingRootView = rootView
        } else {
            hostingView.rootView = rootView
            panelWidth = initialWidth
            layoutPanel()
        }
    }

    private func layoutPanel() {
        guard !bounds.isEmpty else { return }

        let availableWidth = max(0, bounds.width)
        let width = min(availableWidth, clampedWidth(panelWidth))
        let panelFrame = NSRect(
            x: bounds.maxX - width,
            y: bounds.minY,
            width: width,
            height: bounds.height
        )
        hostingView.frame = panelFrame

        // 让 resize 热区跨过面板左边缘，避免拖动时因面板移动而丢失鼠标命中。
        let handleWidth = min(16, max(0, bounds.width))
        resizeHandle.frame = NSRect(
            x: max(bounds.minX, panelFrame.minX - handleWidth / 2),
            y: bounds.minY,
            width: handleWidth,
            height: bounds.height
        )
    }

    private func clampedWidth(_ width: CGFloat) -> CGFloat {
        let lowerBound = max(0, minWidth)
        let upperBound = max(lowerBound, maxWidth)
        return min(upperBound, max(lowerBound, width))
    }

    private func beginResize(with event: NSEvent) {
        guard !bounds.isEmpty else { return }
        isDragging = true
        dragStartX = convert(event.locationInWindow, from: nil).x
        dragStartWidth = panelWidth
        resizeHandle.isDragging = true
    }

    private func continueResize(with event: NSEvent) {
        guard isDragging else { return }
        let currentX = convert(event.locationInWindow, from: nil).x
        panelWidth = clampedWidth(dragStartWidth - (currentX - dragStartX))
        layoutPanel()
    }

    private func endResize() {
        guard isDragging else { return }
        isDragging = false
        resizeHandle.isDragging = false

        if let pendingRootView {
            hostingView.rootView = pendingRootView
            self.pendingRootView = nil
        }
        layoutPanel()
        onResize(panelWidth)
    }
}

@MainActor
private final class TrailingPaneResizeHandle: NSView {
    var onMouseDown: ((NSEvent) -> Void)?
    var onMouseDragged: ((NSEvent) -> Void)?
    var onMouseUp: (() -> Void)?
    var isDragging = false

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        onMouseDown?(event)
    }

    override func mouseDragged(with event: NSEvent) {
        onMouseDragged?(event)
    }

    override func mouseUp(with event: NSEvent) {
        onMouseUp?()
    }
}
#endif
