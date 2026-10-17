import Foundation
import KernelCore
import KitGit
import ProviderGit
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI
import Testing

@testable import PluginGitStash

// MARK: - Test Doubles

/// 记录状态栏写入的最小 `StatusBarProviding` 替身。
@MainActor
private final class MockStatusBarProvider: StatusBarProviding, ObservableObject {
    var statusBarItems: [StatusBarItem] = []

    func registerStatusBarItems(_ items: [StatusBarItem]) {
        statusBarItems = items
    }

    func makeStatusBarView() -> AnyView { AnyView(EmptyView()) }
}

/// 可手动派发场景事件的场景 Provider 替身。
@MainActor
private final class MockSceneProvider: WorkspaceSceneProviding {
    var currentScene: GitOKWorkspaceScene
    let availableScenes: [GitOKWorkspaceScene] = [.git]
    private var subscriptions: [UUID: (WorkspaceSceneEvent) -> Void] = [:]
    private(set) var observerCount = 0

    init(currentScene: GitOKWorkspaceScene = .git) {
        self.currentScene = currentScene
    }

    func selectScene(_ scene: GitOKWorkspaceScene) {
        guard scene != currentScene else { return }
        let from = currentScene
        currentScene = scene
        let event = WorkspaceSceneEvent.sceneChanged(from: from, to: scene)
        subscriptions.values.forEach { $0(event) }
    }

    func addObserver(
        _ callback: @escaping (WorkspaceSceneEvent) -> Void
    ) -> any WorkspaceSceneObserverHandle {
        let token = UUID()
        observerCount += 1
        subscriptions[token] = callback
        return MockSceneHandle { [weak self] in
            self?.subscriptions[token] = nil
            self?.observerCount -= 1
        }
    }
}

@MainActor
private final class MockSceneHandle: WorkspaceSceneObserverHandle {
    private var cancelAction: (() -> Void)?

    init(cancel: @escaping () -> Void) {
        self.cancelAction = cancel
    }

    func cancel() {
        cancelAction?()
        cancelAction = nil
    }
}

/// `ProjectProviding` 的空实现；生命周期测试只关心装配结果。
@MainActor
private final class StubProjectsProvider: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
    func selectCommit(_ commit: GitCommit) {}
    func selectFile(_ path: String?) {}
    func clearCommitSelection() {}
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle { NoopHandle() }
}

@MainActor
private final class NoopHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}

/// 生命周期测试只需「能注册进内核」，不触发任何真实 git 调用，
/// 因此直接使用内核自带的默认实现，避免维护一份 80 个方法的假 Provider。
private typealias StubGitProvider = DefaultGitProvider

// MARK: - Tests

@Suite("GitStashPlugin 生命周期")
@MainActor
struct GitStashPluginLifecycleTests {

    @Test("插件标识与元数据稳定")
    func identity() {
        let plugin = GitStashPlugin()

        #expect(plugin.id == "com.coffic.gitok.plugin.git-stash")
        #expect(plugin.order == 34)
        #expect(plugin.metadata.id == plugin.id)
        #expect(plugin.metadata.name == "Stash")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.stage == .stable)
        #expect(GitStashPlugin.itemID == "com.coffic.gitok.plugin.git-stash.id")
    }

    @Test("无任何 provider 时 onBoot / onShutdown 安全降级")
    func bootWithEmptyKernel() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitStashPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("缺少 StatusBarProviding 时不装配")
    func bootWithoutStatusBar() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitStashPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any StatusBarProviding).self) == nil)
    }

    @Test("缺少 ProjectProviding 时不注册状态栏项")
    func bootWithoutProjects() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        let plugin = GitStashPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("缺少 GitProviding 时不注册状态栏项")
    func bootWithoutGit() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, StubProjectsProvider())
        let plugin = GitStashPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("缺少 WorkspaceSceneProviding 时不注册状态栏项")
    func bootWithoutScene() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, StubProjectsProvider())
        try kernel.registerProvider((any GitProviding).self, StubGitProvider())
        let plugin = GitStashPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("依赖齐备时注册状态栏项并订阅场景")
    func bootRegistersStatusBarItem() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        let scene = MockSceneProvider()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, StubProjectsProvider())
        try kernel.registerProvider((any GitProviding).self, StubGitProvider())
        try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        let plugin = GitStashPlugin()

        try plugin.onBoot(kernel: kernel)

        let item = try #require(statusBar.statusBarItems.first)
        #expect(item.id == GitStashPlugin.itemID)
        #expect(statusBar.statusBarItems.count == 1)
        #expect(scene.observerCount == 1)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("onShutdown 取消场景订阅并移除状态栏项")
    func shutdownCleansUp() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        let scene = MockSceneProvider()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, StubProjectsProvider())
        try kernel.registerProvider((any GitProviding).self, StubGitProvider())
        try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        let plugin = GitStashPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        #expect(scene.observerCount == 0)
    }

    @Test("onShutdown 在从未 boot 时也安全")
    func shutdownWithoutBoot() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        let plugin = GitStashPlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    @Test("重复 boot 不产生重复状态栏项")
    func repeatedBootDoesNotDuplicate() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, StubProjectsProvider())
        try kernel.registerProvider((any GitProviding).self, StubGitProvider())
        try kernel.registerProvider((any WorkspaceSceneProviding).self, MockSceneProvider())
        let plugin = GitStashPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.count == 1)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("onRegister / onUnregister 在无 DocsView 时安全降级")
    func registerWithoutDocs() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitStashPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }
}

// MARK: - 场景能力与观察者

@Suite("GitStash 场景能力与观察者")
@MainActor
struct GitStashSceneObserverTests {

    @Test("Adapter 透传当前场景")
    func adapterForwardsCurrentScene() {
        let provider = MockSceneProvider(currentScene: .icon)
        let adapter = GitStashSceneCapabilityAdapter(scene: provider)

        #expect(adapter.currentScene == .icon)
    }

    @Test("Adapter 透传事件订阅")
    func adapterForwardsObserver() {
        let provider = MockSceneProvider()
        let adapter = GitStashSceneCapabilityAdapter(scene: provider)

        adapter.addObserver { _ in }

        #expect(provider.observerCount == 1)
    }

    @Test("初始化时按当前场景同步可见性")
    func syncInitialScene() {
        let provider = MockSceneProvider(currentScene: .banner)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)

        let observer = GitStashSceneObserver(
            capability: GitStashSceneCapabilityAdapter(scene: provider),
            viewModel: viewModel
        )
        defer { observer.cancel() }

        #expect(viewModel.isActive == false)
    }

    @Test("切到目标场景后变为活跃")
    func becomesActiveOnTargetScene() {
        let provider = MockSceneProvider(currentScene: .banner)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitStashSceneObserver(
            capability: GitStashSceneCapabilityAdapter(scene: provider),
            viewModel: viewModel
        )
        defer { observer.cancel() }

        provider.selectScene(.git)

        #expect(viewModel.isActive)
    }

    @Test("切离目标场景后变为非活跃")
    func becomesInactiveWhenLeaving() {
        let provider = MockSceneProvider(currentScene: .git)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitStashSceneObserver(
            capability: GitStashSceneCapabilityAdapter(scene: provider),
            viewModel: viewModel
        )
        defer { observer.cancel() }
        #expect(viewModel.isActive)

        provider.selectScene(.icon)

        #expect(viewModel.isActive == false)
    }

    @Test("cancel 后不再转发场景事件")
    func cancelStopsForwarding() {
        let provider = MockSceneProvider(currentScene: .banner)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitStashSceneObserver(
            capability: GitStashSceneCapabilityAdapter(scene: provider),
            viewModel: viewModel
        )
        observer.cancel()

        provider.selectScene(.git)

        #expect(viewModel.isActive == false)
    }

    @Test("cancel 可重复调用且幂等")
    func cancelIsIdempotent() {
        let provider = MockSceneProvider(currentScene: .git)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitStashSceneObserver(
            capability: GitStashSceneCapabilityAdapter(scene: provider),
            viewModel: viewModel
        )

        observer.cancel()
        observer.cancel()

        #expect(viewModel.isActive)
    }
}

// MARK: - 项目观察模型

/// 可手动派发项目事件的 `ProjectProviding` 替身。
@MainActor
private final class ObservableProjectsProvider: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?

    private var callbacks: [(ProjectProvidingEvent) -> Void] = []
    private(set) var observerCount = 0

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
    func selectCommit(_ commit: GitCommit) {}
    func selectFile(_ path: String?) {}
    func clearCommitSelection() {}

    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        observerCount += 1
        callbacks.append(callback)
        return NoopHandle()
    }

    func emit(_ event: ProjectProvidingEvent) {
        callbacks.forEach { $0(event) }
    }
}

@Suite("ProjectObservationModel")
@MainActor
struct ProjectObservationModelTests {

    @Test("订阅后建立观察者")
    func registersObserver() {
        let provider = ObservableProjectsProvider()
        let model = ProjectObservationModel(projects: provider)

        #expect(provider.observerCount == 1)
        _ = model
    }

    @Test("selectionChanged 与 dataChanged 递增 revision")
    func bumpsRevisionOnRelevantEvents() {
        let provider = ObservableProjectsProvider()
        let model = ProjectObservationModel(projects: provider)

        provider.emit(.selectionChanged(projectID: nil))
        #expect(model.revision == 1)

        provider.emit(.dataChanged)
        #expect(model.revision == 2)
    }

    @Test("无关事件不递增 revision")
    func ignoresIrrelevantEvents() {
        let provider = ObservableProjectsProvider()
        let model = ProjectObservationModel(projects: provider)

        provider.emit(.projectsChanged)
        provider.emit(.currentFileChanged)
        provider.emit(.commitSelectionChanged)

        #expect(model.revision == 0)
    }

    @Test("初始 revision 为 0")
    func initialRevision() {
        let provider = ObservableProjectsProvider()
        let model = ProjectObservationModel(projects: provider)

        #expect(model.revision == 0)
    }
}
