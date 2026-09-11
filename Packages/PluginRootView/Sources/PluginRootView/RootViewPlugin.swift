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
import ProviderDocsView

// MARK: - RootViewPlugin

/// 根视图插件：实现 `RootViewProviding` 能力，替换宿主的默认实现。
///
/// 在 `onBoot` 中注销 `ProviderFactory` 注册的 `DefaultRootViewProvider`，
/// 替换为插件自有的 `GitOKRootViewProvider`；其他插件（Toast、GitDiff 等）
/// 通过 `kernel.resolveProvider(RootViewProviding.self)` 解析到的是本插件
/// 注册的实现，行为与默认实现完全兼容（所有 setter / overlay / trailing pane
/// 语义不变）。
///
/// 同时监听 `ProjectProviding` 的项目列表与当前项目：统一决定工作区是无项目、
/// 项目已从磁盘消失，还是可以挂载业务插件视图。不可用时由根布局直接替换工作区，
/// 避免业务插件先挂载并启动 Git loading。
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

    private let workspaceModel = RootWorkspaceModel()

    public init() {
        self.provider = GitOKRootViewProvider()
    }

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { RootViewAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        // 替换宿主的默认实现为插件自有实现。
        kernel.unregisterProvider((any RootViewProviding).self)
        try kernel.registerProvider((any RootViewProviding).self, provider)
        if Self.verbose {
            Self.logger.info("\(self.t)Replaced default RootViewProviding with GitOKRootViewProvider")
        }

        // 解析项目服务。
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip no-project guide")
            return
        }

        provider.setWorkspaceUnavailableView(
            AnyView(
                RootWorkspaceUnavailableView(
                    model: workspaceModel,
                    projects: projects,
                    cloneRepository: kernel.resolveProvider((any CloneRepositoryProviding).self)
                )
            )
        )

        // 项目列表 / 当前选择发生变化时同步更新根布局门控。
        observer = RootViewProjectObserver(
            projects: projects,
            cloneRepository: kernel.resolveProvider((any CloneRepositoryProviding).self),
            onWorkspaceChanged: { [weak self, weak projects] in
                guard let self, let projects else { return }
                self.updateWorkspaceState(
                    projects: projects,
                    cloneRepository: kernel.resolveProvider((any CloneRepositoryProviding).self)
                )
            }
        )
        updateWorkspaceState(
            projects: projects,
            cloneRepository: kernel.resolveProvider((any CloneRepositoryProviding).self)
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        observer?.cancel()
        observer = nil
        provider.setWorkspaceUnavailableView(nil)
        workspaceModel.reset()

        // 恢复默认实现，保证后续流程仍可解析 RootViewProviding。
        kernel.unregisterProvider((any RootViewProviding).self)
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        if Self.verbose {
            Self.logger.info("\(self.t)Restored default RootViewProviding")
        }
    }

    private func updateWorkspaceState(
        projects: any ProjectProviding,
        cloneRepository: (any CloneRepositoryProviding)?
    ) {
        let state: RootWorkspaceState
        if let project = projects.currentProject {
            if cloneRepository?.isCloning(for: project.url) == true {
                state = .cloning
            } else if FileManager.default.fileExists(atPath: project.url.path) {
                state = .ready
            } else {
                state = .projectMissing(path: project.url.path)
            }
        } else {
            state = .noProject
        }
        workspaceModel.update(state: state, project: projects.currentProject)
        provider.setWorkspaceState(state)
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

    public var isSidebarViewHidden: Bool { inner.isSidebarViewHidden }

    public func setSidebarViewHidden(_ hidden: Bool) {
        inner.setSidebarViewHidden(hidden)
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

    public var workspaceState: RootWorkspaceState { inner.workspaceState }

    public func setWorkspaceState(_ state: RootWorkspaceState) {
        inner.setWorkspaceState(state)
    }

    public func setWorkspaceUnavailableView(_ view: AnyView?) {
        inner.setWorkspaceUnavailableView(view)
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
