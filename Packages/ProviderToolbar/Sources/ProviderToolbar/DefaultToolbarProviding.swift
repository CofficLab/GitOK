import Combine
import LumiUI
import SwiftUI

#if os(macOS)
import AppKit
#endif

/// `ToolbarProviding` 的默认实现：持有注入的 `ToolbarItem`，
/// 并按 `placement`（leading / center / trailing）渲染为 44pt 高的工具栏。
///
/// 尺寸与旧版 Lumi（`FactoryCore.AppTitleToolbar`）保持完全一致：
/// - 高度 44pt，左侧红绿灯预留 76pt（`trafficLightReserveWidth`）；
///   全屏窗口没有红绿灯时自动取消这段预留；
/// - 整条工具栏可作为窗口拖拽区（macOS）；
/// - center 项绝对居中（`maxWidth 420` + 水平 padding 88），
///   不被 leading / trailing 内容位置影响；
/// - 背景使用 `AppToolbarContainer(style: .toolbar)`、前景 `theme.textPrimary`
///   （与旧版 `AppTitleToolbar` 一致）。
@MainActor
public final class DefaultToolbarProviding: ToolbarProviding, ObservableObject {
    @Published public private(set) var toolbarItems: [ToolbarItem] = []
    @Published public private(set) var visibleCategories: Set<ToolbarItemCategory>

    private var baseVisibleCategories: Set<ToolbarItemCategory>
    private var hiddenCategoriesBySource: [String: Set<ToolbarItemCategory>] = [:]

    public init(visibleCategories: Set<ToolbarItemCategory> = Set(ToolbarItemCategory.allCases)) {
        self.visibleCategories = visibleCategories
        self.baseVisibleCategories = visibleCategories
    }

    public func registerToolbarItems(_ items: [ToolbarItem]) {
        toolbarItems = items
    }

    public func setVisibleCategories(_ categories: Set<ToolbarItemCategory>) {
        guard baseVisibleCategories != categories else { return }
        baseVisibleCategories = categories
        refreshVisibleCategories()
    }

    public func setHiddenCategories(_ categories: Set<ToolbarItemCategory>, for source: String) {
        if categories.isEmpty {
            hiddenCategoriesBySource.removeValue(forKey: source)
        } else {
            hiddenCategoriesBySource[source] = categories
        }
        refreshVisibleCategories()
    }

    private func refreshVisibleCategories() {
        let hiddenCategories = hiddenCategoriesBySource.values.reduce(into: Set<ToolbarItemCategory>()) {
            $0.formUnion($1)
        }
        let effectiveCategories = baseVisibleCategories.subtracting(hiddenCategories)
        guard visibleCategories != effectiveCategories else { return }
        visibleCategories = effectiveCategories
    }

    public func makeToolbarView() -> AnyView {
        AnyView(ToolbarView(provider: self))
    }

    public var visibleToolbarItems: [ToolbarItem] {
        toolbarItems.filter { visibleCategories.contains($0.category) }
    }
}

/// 按 placement 渲染工具栏项的视图。
private struct ToolbarView: View {
    @LumiTheme private var theme
    @StateObject private var windowState = ToolbarWindowState()

    @ObservedObject var provider: DefaultToolbarProviding

    /// 与旧版 `AppTitleToolbar` 保持一致的尺寸常量。
    private let height: CGFloat = 44
    private let trafficLightReserveWidth: CGFloat = 76

    var body: some View {
        let items = provider.visibleToolbarItems
        let leading = items.filter { $0.placement == .leading }
        let center = items.filter { $0.placement == .center }
        let trailing = items.filter { $0.placement == .trailing }
        let leadingInset = windowState.isFullScreen ? 0 : trafficLightReserveWidth

        AppToolbarContainer(
            height: height,
            backgroundStyle: .toolbar,
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        ) {
            ZStack {
                #if os(macOS)
                WindowDragRegion(windowState: windowState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                #endif

                HStack(spacing: 8) {
                    // 红绿灯预留：hiddenTitleBar 下红绿灯悬浮于左上角，
                    // leading 项从此宽度之后开始排布；全屏时没有预留区。
                    Color.clear
                        .frame(width: leadingInset, height: height)
                        .accessibilityHidden(true)

                    group(leading)

                    Spacer(minLength: 12)

                    group(trailing)
                }
                .padding(.trailing, 12)
                .frame(maxWidth: .infinity, alignment: .leading)

                // center 项绝对居中，maxWidth 420，并左右留出红绿灯空间。
                group(center)
                    .frame(maxWidth: 420)
                    .padding(.horizontal, leadingInset + 12)
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(theme.textPrimary)
    }

    private func group(_ items: [ToolbarItem]) -> some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                item.makeView()
                    .help(item.title)
            }
        }
        .frame(height: height)
        .fixedSize(horizontal: true, vertical: false)
    }
}

#if os(macOS)
/// 整条工具栏的窗口拖拽区：与旧版 `AppTitleToolbar` 的拖拽行为一致。
@MainActor
private struct WindowDragRegion: NSViewRepresentable {
    let windowState: ToolbarWindowState

    func makeNSView(context: Context) -> DragRegionView {
        DragRegionView(windowState: windowState)
    }

    func updateNSView(_ nsView: DragRegionView, context: Context) {
        windowState.attach(to: nsView.window)
    }
}

@MainActor
private final class DragRegionView: NSView {
    private let windowState: ToolbarWindowState

    init(windowState: ToolbarWindowState) {
        self.windowState = windowState
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        windowState.attach(to: window)
    }

    override var mouseDownCanMoveWindow: Bool {
        true
    }
}

/// Tracks the host window so title-bar-specific spacing does not leak into full screen.
@MainActor
private final class ToolbarWindowState: NSObject, ObservableObject {
    @Published private(set) var isFullScreen = false

    private weak var window: NSWindow?
    private var refreshScheduled = false

    func attach(to window: NSWindow?) {
        guard self.window !== window else {
            refresh()
            return
        }

        NotificationCenter.default.removeObserver(self)
        self.window = window
        refresh()

        guard let window else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFullScreenChange),
            name: NSWindow.didEnterFullScreenNotification,
            object: window
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFullScreenChange),
            name: NSWindow.didExitFullScreenNotification,
            object: window
        )
    }

    @objc private func handleFullScreenChange() {
        refresh()
    }

    private func refresh() {
        let nextValue = window?.styleMask.contains(.fullScreen) == true
        guard isFullScreen != nextValue, !refreshScheduled else { return }

        // `attach(to:)` is called from NSViewRepresentable.updateNSView, which can
        // run during SwiftUI's layout pass. Publishing here makes SwiftUI mutate
        // its graph while that pass is still active and produces the re-entrant
        // "Publishing changes from within view updates" warning.
        refreshScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.refreshScheduled = false
            let currentValue = self.window?.styleMask.contains(.fullScreen) == true
            guard self.isFullScreen != currentValue else { return }
            self.isFullScreen = currentValue
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
#endif
