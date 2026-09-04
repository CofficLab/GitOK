import Combine
import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderCloneRepository
import ProviderProjects
import ProviderRailView
import ProviderRootView
import SwiftUI

// MARK: - RootViewPlugin

/// 根视图插件：实现 `RootViewProviding` 能力，替换宿主的默认实现。
///
/// 在 `onBoot` 中注销 `ProviderFactory` 注册的 `DefaultRootViewProvider`，
/// 替换为插件自有的 `GitOKRootViewProvider`；其他插件（Toast、GitDiff 等）
/// 通过 `kernel.resolveProvider(RootViewProviding.self)` 解析到的是本插件
/// 注册的实现，行为与默认实现完全兼容（所有 setter / overlay / trailing pane
/// 语义不变）。
///
/// 同时监听 `ProjectProviding` 的项目列表变化：当没有任何项目时，
/// 通过 overlay 在根视图最上层显示 `NoProjectGuideView`，引导用户添加或克隆仓库；
/// 项目列表不再为空时自动隐藏引导视图。
///
/// 替换式注册模式与 `ToastSuperPlugin` 一致：尽早完成替换（`order = 5`），
/// 保证后续插件在 `onBoot` 中 resolve 到的是真实实现。
@MainActor
public final class RootViewPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.root-view", category: "RootView")
    nonisolated public static let emoji = "🏠"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.root-view"
    /// 必须在所有消费 RootViewProviding 的插件之前启动。
    public let order = 5
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.root-view",
        name: "Root View",
        description: "Provides the root view layout, replacing the default provider",
        category: .core,
        stage: .stable,
        policy: .required
    )

    /// 插件自有的根视图 Provider，替换默认实现。
    public let provider: GitOKRootViewProvider

    /// 项目监听者：装配阶段创建，卸载时取消。
    private var observer: RootViewProjectObserver?

    /// 引导视图显隐状态：驱动 overlay 内容切换。
    private let guideState = NoProjectGuideState()

    /// overlay 稳定 ID（供挂载 / 撤回）。
    static let noProjectOverlayID = "no-project-guide"

    public init() {
        self.provider = GitOKRootViewProvider()
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        // 替换宿主的默认实现为插件自有实现。
        kernel.unregisterProvider((any RootViewProviding).self)
        try kernel.registerProvider((any RootViewProviding).self, provider)
        if Self.verbose {
            Self.logger.info("\(self.t)Replaced default RootViewProviding with GitOKRootViewProvider")
        }

        // 解析项目服务与克隆仓库能力。
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip no-project guide")
            return
        }
        let cloneProvider = kernel.resolveProvider((any CloneRepositoryProviding).self)

        // 初始同步：如果启动时就没有项目，立即显示引导视图。
        guideState.showGuide = projects.projects.isEmpty

        // 创建项目监听：项目列表变化时更新引导视图显隐。
        let guideState = self.guideState
        observer = RootViewProjectObserver(
            projects: projects,
            onProjectsChanged: { [weak guideState, weak projects] in
                guard let guideState, let projects else { return }
                guideState.showGuide = projects.projects.isEmpty
            }
        )

        // 挂载引导 overlay：始终注册，内容根据 guideState 条件渲染。
        provider.addOverlays([
            RootOverlayItem(id: Self.noProjectOverlayID, order: -100) { [guideState] content in
                NoProjectGuideOverlay(
                    content: content,
                    guideState: guideState,
                    projects: projects,
                    cloneProvider: cloneProvider
                )
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        observer?.cancel()
        observer = nil
        provider.removeOverlays(ids: [Self.noProjectOverlayID])

        // 恢复默认实现，保证后续流程仍可解析 RootViewProviding。
        kernel.unregisterProvider((any RootViewProviding).self)
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        if Self.verbose {
            Self.logger.info("\(self.t)Restored default RootViewProviding")
        }
    }
}

// MARK: - NoProjectGuideState

/// 引导视图显隐状态：ObservableObject 驱动 overlay 内容响应式切换。
@MainActor
final class NoProjectGuideState: ObservableObject {
    @Published var showGuide: Bool
    init(showGuide: Bool = false) {
        self.showGuide = showGuide
    }
}

// MARK: - NoProjectGuideOverlay

/// 引导 overlay：根据 `guideState.showGuide` 条件渲染。
///
/// 显示引导视图时覆盖整个根视图；隐藏时透明传递底层内容。
@MainActor
private struct NoProjectGuideOverlay: View {
    let content: AnyView
    @ObservedObject var guideState: NoProjectGuideState
    let projects: any ProjectProviding
    let cloneProvider: (any CloneRepositoryProviding)?

    var body: some View {
        ZStack {
            content
            if guideState.showGuide {
                NoProjectGuideView(projects: projects, cloneProvider: cloneProvider)
            }
        }
        // RootView is rendered in a hidden-title-bar window. The overlay is
        // outside DefaultRootHostView's safe-area configuration, so it must
        // opt out explicitly to cover the title-bar/toolbar region as well.
        .ignoresSafeArea()
    }
}

// MARK: - GitOKRootViewProvider

/// `RootViewProviding` 的 GitOK 实现：持有注入的工具栏、侧边栏、Rail、内容 Header、
/// 主内容视图与 Footer，组合成「顶部工具栏 + 内容区（左侧侧边栏，右侧 Rail）」
/// 的根布局。
///
/// 与 `DefaultRootViewProvider` 行为完全兼容，所有 setter / overlay /
/// trailing pane / rail visibility / content footer height 语义一致；
/// 视图组合委托给 `DefaultRootViewProvider` 完成。
@MainActor
public final class GitOKRootViewProvider: RootViewProviding, ObservableObject, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.root-view", category: "GitOKRootViewProvider")
    nonisolated public static let emoji = "🏠"
    nonisolated static let verbose = false

    /// 内部委托的默认实现，负责实际的视图组合与渲染。
    private let inner = DefaultRootViewProvider()

    public init() {
        if Self.verbose {
            Self.logger.info("\(self.t)GitOKRootViewProvider initialized")
        }
    }

    // MARK: - Overlays

    public var overlays: [RootOverlayItem] { inner.overlays }

    public func addOverlays(_ overlays: [RootOverlayItem]) {
        inner.addOverlays(overlays)
    }

    public func removeOverlays(ids: Set<String>) {
        inner.removeOverlays(ids: ids)
    }

    // MARK: - Toolbar

    public func setToolbarView(_ view: AnyView?) {
        inner.setToolbarView(view)
    }

    // MARK: - Status Bar

    public func setStatusBarView(_ view: AnyView?) {
        inner.setStatusBarView(view)
    }

    // MARK: - Sidebar

    public func setSidebarView(_ view: AnyView?) {
        inner.setSidebarView(view)
    }

    // MARK: - Rail

    public func setRailView(_ view: AnyView?) {
        inner.setRailView(view)
    }

    public var isRailViewVisible: Bool { inner.isRailViewVisible }

    public func setRailViewVisible(_ visible: Bool) {
        inner.setRailViewVisible(visible)
    }

    public func bindRailViewVisibility(to publisher: AnyPublisher<Bool, Never>) {
        inner.bindRailViewVisibility(to: publisher)
    }

    public var railWidth: RailViewWidth { inner.railWidth }

    public func bindRailViewWidth(
        to publisher: AnyPublisher<RailViewWidth, Never>,
        onResize: @escaping @MainActor (CGFloat) -> Void
    ) {
        inner.bindRailViewWidth(to: publisher, onResize: onResize)
    }

    // MARK: - Content Header

    public func setContentHeaderView(_ view: AnyView?) {
        inner.setContentHeaderView(view)
    }

    public var isContentHeaderViewHidden: Bool { inner.isContentHeaderViewHidden }

    public func setContentHeaderViewHidden(_ hidden: Bool) {
        inner.setContentHeaderViewHidden(hidden)
    }

    // MARK: - Content View

    public func setContentView(_ view: AnyView?) {
        inner.setContentView(view)
    }

    public var isContentViewHidden: Bool { inner.isContentViewHidden }

    public func setContentViewHidden(_ hidden: Bool) {
        inner.setContentViewHidden(hidden)
    }

    // MARK: - Content Footer

    public func setContentFooterView(_ view: AnyView?) {
        inner.setContentFooterView(view)
    }

    public var isContentFooterViewHidden: Bool { inner.isContentFooterViewHidden }

    public func setContentFooterViewHidden(_ hidden: Bool) {
        inner.setContentFooterViewHidden(hidden)
    }

    public var contentFooterHeight: ContentFooterHeight { inner.contentFooterHeight }

    public var contentFooterHeightPublisher: AnyPublisher<ContentFooterHeight, Never> {
        inner.contentFooterHeightPublisher
    }

    public func activateContentFooterHeightProfile(
        ownerID: String,
        recommended: ContentFooterHeight,
        store: (any ContentFooterHeightStoring)?
    ) {
        inner.activateContentFooterHeightProfile(ownerID: ownerID, recommended: recommended, store: store)
    }

    public func deactivateContentFooterHeightProfile(ownerID: String) {
        inner.deactivateContentFooterHeightProfile(ownerID: ownerID)
    }

    public func saveCurrentContentFooterHeight(_ height: CGFloat) {
        inner.saveCurrentContentFooterHeight(height)
    }

    // MARK: - Trailing Pane

    public func setTrailingPane(_ pane: RootTrailingPane?) {
        inner.setTrailingPane(pane)
    }

    // MARK: - Root View

    public func makeRootView() -> AnyView {
        inner.makeRootView()
    }
}
