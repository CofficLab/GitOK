import Combine
import LumiUI
import LumiLoggingKit
import os
import ProviderRailView
import ProviderRootView
import SwiftUI

/// GitOK 的根视图 Provider：继承共享 `DefaultRootViewProviding` 的区域存储、
/// 叠层、trailing pane 与 Content Footer 高度 profile 契约，叠加 GitOK 宿主
/// 专属能力：
///
/// - 工作区状态门控（`workspaceState` / `workspaceUnavailableView`）；
/// - sidebar 宽度磁盘持久化（`SidebarWidthStoring`）；
/// - 注入守卫（nil 态相同则跳过赋值，避免视图更新期间发布 objectWillChange）；
/// - Rail 移除 / 恢复时保留最近的可见状态；
/// - Rail 显隐 / 宽度绑定走 provider 的 publisher（GitOK 的 Rail provider
///   以 sections 为主，observer 事件不覆盖 sections 变化）；
/// - `makeRootView()` 组合 GitOK 的 macOS workbench 布局。
@MainActor
open class DefaultRootViewProvider: DefaultRootViewProviding, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.lumi.provider-root-view", category: "ProviderRootView")
    nonisolated public static let emoji = "🏠"
    nonisolated static let verbose = false

    @Published public private(set) var workspaceState: RootWorkspaceState = .ready
    @Published private(set) var workspaceUnavailableView: AnyView?
    @Published public private(set) var sidebarWidth: SidebarWidth

    private var railVisibilitySubscription: AnyCancellable?
    private var railWidthSubscription: AnyCancellable?
    private var railWidthResizeHandler: (@MainActor (CGFloat) -> Void)?
    private var sidebarWidthStore: (any SidebarWidthStoring)?
    private var lastRailViewVisibility = true

    /// - Parameter sidebarWidthStore: sidebar 宽度偏好的持久化存储。
    ///   传 `nil` 时退化为纯内存模式（预览 / 测试场景）：宽度可读可写，只是不落盘。
    ///   生产环境由宿主注入插件数据目录对应的磁盘实现。
    public init(sidebarWidthStore: (any SidebarWidthStoring)? = nil) {
        self.sidebarWidthStore = sidebarWidthStore
        let restoredWidth = sidebarWidthStore?.loadWidth() ?? SidebarWidth.standard.idealWidth
        self.sidebarWidth = SidebarWidth.standard.withIdealWidth(
            SidebarWidth.standard.clamped(restoredWidth)
        )
        super.init()
        if Self.verbose {
            Self.logger.info("\(self.t)DefaultRootViewProvider initialized")
        }
    }

    // MARK: - 注入守卫（值相同则跳过赋值）

    /// 判断两次注入的视图是否「相同」：仅比较有值/无值状态。
    ///
    /// `AnyView` 不遵循 `Equatable`，SwiftUI 也未公开 unerase API（反射内部
    /// storage 在 Release 下不可靠）。因此这里采用保守且可预测的判定：
    /// - 状态相同（均为 nil 或均为非 nil）→ 视为相同，跳过赋值；
    /// - 状态不同（nil ↔ 非 nil）→ 视为变化，正常更新。
    ///
    /// 目的：装配流程可能重复调用注入方法（如宿主重建视图树时）
    /// 导致 App body 重求值后再次装配），重复赋值 `@Published` 会在视图更新期间
    /// 发布变更，触发 SwiftUI 的 "Publishing changes from within view updates
    /// is not allowed" 并可能形成循环。状态相同即跳过，避免无意义发布。
    ///
    /// 注意：这是保守近似 —— 已注入非 nil 视图后，再次注入任意新视图（含不同
    /// 类型）都会被跳过。Lumi 架构下视图内容更新由视图内部状态驱动（Provider
    /// 的 `@Published`/`objectWillChange`），无需重新注入新 `AnyView`；若确有
    /// Provider 需要强制替换，可先传 nil 再传新值。
    private func isSameView(_ lhs: AnyView?, _ rhs: AnyView?) -> Bool {
        (lhs == nil) == (rhs == nil)
    }

    override open func setView(_ view: AnyView?, for region: RootViewRegion) {
        guard !isSameView(self.view(for: region), view) else { return }
        super.setView(view, for: region)
    }

    override open func setToolbarView(_ view: AnyView?) {
        guard !isSameView(toolbarView, view) else { return }
        super.setToolbarView(view)
    }

    override open func setContentHeaderView(_ view: AnyView?) {
        guard !isSameView(contentHeaderView, view) else { return }
        super.setContentHeaderView(view)
    }

    override open func setContentView(_ view: AnyView?) {
        guard !isSameView(contentView, view) else { return }
        super.setContentView(view)
    }

    override open func setContentFooterView(_ view: AnyView?) {
        guard !isSameView(contentFooterView, view) else { return }
        super.setContentFooterView(view)
    }

    override open func setRegionHidden(_ hidden: Bool, for region: RootViewRegion) {
        guard isRegionHidden(region) != hidden else { return }
        super.setRegionHidden(hidden, for: region)
    }

    // MARK: - Rail

    override open func setRailView(_ view: AnyView?) {
        guard !isSameView(railView, view) else { return }
        if view == nil {
            // `setRailView(nil)` can be a temporary host-level replacement. Keep
            // the provider's latest visibility so restoring the Rail view does
            // not show an empty area while its tabs are still hidden.
            if isRailViewVisible {
                isRailViewVisible = false
            }
        } else if railView == nil {
            setRailViewVisible(lastRailViewVisibility)
        }
        super.setRailView(view)
    }

    override open func setRailViewVisible(_ visible: Bool) {
        guard isRailViewVisible != visible else { return }
        lastRailViewVisibility = visible
        super.setRailViewVisible(visible)
    }

    override open func bindRailViewVisibility(to provider: any RailViewProviding) {
        railVisibilitySubscription = provider.railVisibilityPublisher.sink { [weak self] visible in
            // Rail 的可见性来自主线程上的 provider 状态快照（例如当前项目
            // 是否仍存在于磁盘），必须在同一轮状态传播中更新根布局。异步再
            // hop 到 MainActor 会让 Rail 先挂载一帧，CommitRailView 也就会
            // 先显示 loading，随后才被移除。
            self?.setRailViewVisible(visible)
        }
    }

    override open func bindRailViewWidth(
        to provider: any RailViewProviding,
        onResize: @escaping @MainActor (CGFloat) -> Void
    ) {
        railWidthResizeHandler = onResize
        railWidthSubscription = provider.railWidthPublisher.sink { [weak self] width in
            Task { @MainActor [weak self] in
                self?.railWidth = width
            }
        }
    }

    override open func saveRailViewWidth(_ width: CGFloat) {
        railWidthResizeHandler?(width)
    }

    // MARK: - 工作区状态

    public func setWorkspaceState(_ state: RootWorkspaceState) {
        guard workspaceState != state else { return }
        workspaceState = state
    }

    public func setWorkspaceUnavailableView(_ view: AnyView?) {
        guard !isSameView(workspaceUnavailableView, view) else { return }
        workspaceUnavailableView = view
    }

    // MARK: - Sidebar 宽度

    func saveSidebarWidth(_ width: CGFloat) {
        let resolvedWidth = sidebarWidth.clamped(width)
        sidebarWidthStore?.saveWidth(resolvedWidth)
        let updatedWidth = sidebarWidth.withIdealWidth(resolvedWidth)
        if sidebarWidth != updatedWidth {
            sidebarWidth = updatedWidth
        }
    }

    /// 注入 sidebar 宽度的持久化目录。
    ///
    /// 由宿主在装配阶段调用（对齐 `DefaultThemeProviding.setStorageDirectory`
    /// 的做法）：宽度偏好改由插件数据目录下的 `settings.plist` 承载，
    /// 不再依赖 `UserDefaults`。
    ///
    /// - Parameter directory: 插件数据目录；不存在会自动创建。
    public func setStorageDirectory(_ directory: URL) {
        let store = PluginDataSidebarWidthStore(directory: directory)
        sidebarWidthStore = store
        let restoredWidth = store.loadWidth() ?? sidebarWidth.idealWidth
        let updatedWidth = sidebarWidth.withIdealWidth(sidebarWidth.clamped(restoredWidth))
        if sidebarWidth != updatedWidth {
            sidebarWidth = updatedWidth
        }
    }

    // MARK: - Content Footer

    public var contentFooterHeightPublisher: AnyPublisher<ContentFooterHeight, Never> {
        $contentFooterHeight.eraseToAnyPublisher()
    }

    // MARK: - Trailing Pane

    /// 类型化的 trailing pane 访问器：GitOK 的面板都是 `RootTrailingPane`。
    /// 基类 `trailingPane` 是 public 非 open 的可变属性，无法协变 override，
    /// 故以异名只读访问器提供类型收窄。
    public var rootTrailingPane: RootTrailingPane? {
        trailingPane as? RootTrailingPane
    }

    override open func setTrailingPane(_ pane: RootViewPane?) {
        guard pane !== trailingPane else { return }
        super.setTrailingPane(pane)
    }

    // MARK: - Root View

    override open func makeRootView() -> AnyView {
        if Self.verbose {
            Self.logger.debug("\(self.t)make root view: toolbar=\(self.toolbarView == nil ? "nil" : "set"), sidebar=\(self.sidebarView == nil ? "nil" : "set"), rail=\(self.railView == nil ? "nil" : "set"), content=\(self.contentView == nil ? "nil" : "set"), footer=\(self.contentFooterView == nil ? "nil" : "set")")
        }
        var root = AnyView(DefaultRootHostView(provider: self))
        for overlay in overlays { root = overlay.wrap(root) }
        return root
    }

    // MARK: - 显示条件

    /// 是否存在可渲染的活跃内容。
    ///
    /// 内容插件的容器状态不是根视图渲染的必要条件。ChatPanel 由
    /// 侧边栏 + ChatSection 驱动，只要 trailing pane 可见就应正常显示。
    var hasActiveContent: Bool {
        return contentHeaderView != nil
            || contentView != nil
            || (contentFooterView != nil && !isContentFooterViewHidden)
            || trailingPane?.isVisible == true
    }
}