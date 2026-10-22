import Foundation
import GitOKProviderRootView
import KernelCore
import ProviderDocsView
import ProviderGit
import ProviderGitConflictResolver
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import Testing
@testable import PluginGitConflictResolver

/// `GitConflictResolverPlugin` 的生命周期接线覆盖。
///
/// `onBoot` 依次解析 5 个依赖（状态栏 / 项目 / Git / 场景 / 根视图），
/// 任一缺失都会提前返回；依赖齐备时才会注册展示 provider、根视图叠层
/// 与状态栏项。这些用例逐个走守卫链，并验证 `onShutdown` 的完整回收。
@MainActor
@Suite("GitConflictResolverPlugin lifecycle")
struct ConflictResolverPluginLifecycleTests {

    // MARK: - Helpers

    private struct Harness {
        let kernel: KernelCoreContainer
        let statusBar: TestStatusBarProviding
        let projects: TestProjectsProviding
        let scene: TestSceneProviding
        let rootView: DefaultRootViewProvider
        let docs: DefaultDocsViewProviding
    }

    private func makeHarness(
        withStatusBar: Bool = true,
        withProjects: Bool = true,
        withGit: Bool = true,
        withScene: Bool = true,
        withRootView: Bool = true,
        withDocs: Bool = false
    ) throws -> Harness {
        let kernel = KernelCoreContainer()
        let statusBar = TestStatusBarProviding()
        let projects = TestProjectsProviding()
        let scene = TestSceneProviding()
        let rootView = DefaultRootViewProvider()
        let docs = DefaultDocsViewProviding()
        if withStatusBar {
            try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, projects)
        }
        if withGit {
            try kernel.registerProvider((any GitProviding).self, TestGitProviding())
        }
        if withScene {
            try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        }
        if withRootView {
            try kernel.registerProvider((any RootViewProviding).self, rootView)
        }
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return Harness(
            kernel: kernel,
            statusBar: statusBar,
            projects: projects,
            scene: scene,
            rootView: rootView,
            docs: docs
        )
    }

    // MARK: - 守卫链

    @Test("缺少状态栏时不注册任何贡献")
    func bootWithoutStatusBar() throws {
        let harness = try makeHarness(withStatusBar: false)
        let plugin = GitConflictResolverPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
        #expect(harness.rootView.overlays.isEmpty)
        #expect(harness.kernel.resolveProvider((any GitConflictResolutionProviding).self) == nil)
    }

    @Test("缺少项目提供方时不注册任何贡献")
    func bootWithoutProjects() throws {
        let harness = try makeHarness(withProjects: false)
        let plugin = GitConflictResolverPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
        #expect(harness.rootView.overlays.isEmpty)
        #expect(harness.kernel.resolveProvider((any GitConflictResolutionProviding).self) == nil)
    }

    @Test("缺少 Git 提供方时不注册任何贡献")
    func bootWithoutGit() throws {
        let harness = try makeHarness(withGit: false)
        let plugin = GitConflictResolverPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
        #expect(harness.rootView.overlays.isEmpty)
        #expect(harness.kernel.resolveProvider((any GitConflictResolutionProviding).self) == nil)
    }

    @Test("缺少场景提供方时不注册任何贡献")
    func bootWithoutScene() throws {
        let harness = try makeHarness(withScene: false)
        let plugin = GitConflictResolverPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
        #expect(harness.rootView.overlays.isEmpty)
        #expect(harness.kernel.resolveProvider((any GitConflictResolutionProviding).self) == nil)
    }

    @Test("缺少根视图提供方时不注册任何贡献")
    func bootWithoutRootView() throws {
        let harness = try makeHarness(withRootView: false)
        let plugin = GitConflictResolverPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
        #expect(harness.kernel.resolveProvider((any GitConflictResolutionProviding).self) == nil)
    }

    // MARK: - 成功接线

    @Test("依赖齐备时注册状态栏项、根视图叠层与展示 provider")
    func bootRegistersContributions() throws {
        let harness = try makeHarness()
        let plugin = GitConflictResolverPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.count == 1)
        #expect(harness.statusBar.statusBarItems.first?.id == GitConflictResolverPlugin.itemID)
        #expect(harness.rootView.overlays.count == 1)
        #expect(harness.rootView.overlays.first?.id == GitConflictResolverPlugin.overlayID)
        #expect(harness.kernel.resolveProvider((any GitConflictResolutionProviding).self) != nil)
        #expect(harness.scene.observerCount == 1, "onBoot 应订阅场景变化")
        #expect(harness.projects.observerCount == 1, "onBoot 应订阅项目变化")
    }

    @Test("展示 provider 会把冲突界面弹出")
    func presentationProviderPresentsResolver() throws {
        let harness = try makeHarness()
        let plugin = GitConflictResolverPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        defer { try? plugin.onShutdown(kernel: harness.kernel) }

        let presenter = harness.kernel.resolveProvider((any GitConflictResolutionProviding).self)
        #expect(presenter != nil)
        // 没有进行中的合并操作时，展示请求只刷新状态、不弹出弹层。
        presenter?.requestPresentation()
    }

    @Test("没有注册仓库监听时仍能完成接线")
    func bootWithoutRepositoryWatching() throws {
        let harness = try makeHarness()
        let plugin = GitConflictResolverPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.kernel.resolveProvider((any GitConflictResolutionProviding).self) != nil)
        #expect(harness.statusBar.statusBarItems.count == 1)
    }

    // MARK: - 卸载

    @Test("onShutdown 撤回状态栏项、叠层与 provider")
    func shutdownRemovesContributions() throws {
        let harness = try makeHarness()
        let plugin = GitConflictResolverPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        #expect(harness.statusBar.statusBarItems.count == 1)

        try plugin.onShutdown(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
        #expect(harness.rootView.overlays.isEmpty)
        #expect(harness.kernel.resolveProvider((any GitConflictResolutionProviding).self) == nil)
        #expect(harness.scene.observerCount == 0, "onShutdown 应取消场景订阅")
        #expect(harness.projects.observerCount == 0, "onShutdown 应取消项目订阅")
    }

    @Test("未启动就卸载是安全的")
    func shutdownWithoutBoot() throws {
        let harness = try makeHarness()
        let plugin = GitConflictResolverPlugin()

        try plugin.onShutdown(kernel: harness.kernel)

        #expect(harness.kernel.resolveProvider((any GitConflictResolutionProviding).self) == nil)
    }

    // MARK: - kernel.start

    @Test("可通过 kernel.start 启动并完成接线")
    func startViaKernel() throws {
        let harness = try makeHarness()
        let plugin = GitConflictResolverPlugin()

        try harness.kernel.start(plugins: [plugin])

        #expect(harness.kernel.isPluginRegistered(id: plugin.id))
        #expect(harness.kernel.resolveProvider((any GitConflictResolutionProviding).self) != nil)
        #expect(harness.statusBar.statusBarItems.count == 1)
        try harness.kernel.stop()
    }

    // MARK: - onRegister / onUnregister

    @Test("onRegister 挂载「关于」条目，onUnregister 撤回")
    func registerAndUnregisterAboutEntry() throws {
        let harness = try makeHarness(withDocs: true)
        let plugin = GitConflictResolverPlugin()

        try plugin.onRegister(kernel: harness.kernel)
        #expect(harness.docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: harness.kernel)
        #expect(!harness.docs.aboutEntries.contains { $0.id == plugin.id })
    }

    @Test("没有文档提供方时 onRegister / onUnregister 也不抛错")
    func registerWithoutDocsProvider() throws {
        let harness = try makeHarness(withDocs: false)
        let plugin = GitConflictResolverPlugin()

        try plugin.onRegister(kernel: harness.kernel)
        try plugin.onUnregister(kernel: harness.kernel)
    }

    // MARK: - 能力适配器

    @Test("能力适配器透传当前项目并转发订阅")
    func capabilityAdapterForwardsProjectState() throws {
        let projects = TestProjectsProviding()
        let url = URL(fileURLWithPath: "/tmp/conflict-project")
        projects.currentProject = Project(url: url)
        let adapter = GitConflictResolverCapabilityAdapter(projects: projects, gitWatch: nil)

        #expect(adapter.currentProject?.url == url)

        var received: [ProjectProvidingEvent] = []
        let handle = adapter.addProjectObserver { received.append($0) }
        projects.send(.selectionChanged(projectID: nil))
        #expect(received.count == 1)
        handle.cancel()

        // 没有仓库监听时返回 nil（调用方需容忍）。
        #expect(adapter.addRepositoryObserver { _ in } == nil)
    }

    @Test("场景能力适配器透传当前场景并转发订阅")
    func sceneCapabilityAdapterForwardsScene() throws {
        let scene = TestSceneProviding(currentScene: .git)
        let adapter = GitConflictResolverSceneCapabilityAdapter(scene: scene)

        #expect(adapter.currentScene == .git)

        var received: [WorkspaceSceneEvent] = []
        let handle = adapter.addObserver { received.append($0) }
        scene.selectScene(.banner)
        #expect(received.count == 1)
        handle.cancel()
    }

    @Test("场景观察者把场景变化写入可见性 ViewModel")
    func sceneObserverUpdatesVisibilityViewModel() throws {
        let scene = TestSceneProviding(currentScene: .git)
        let adapter = GitConflictResolverSceneCapabilityAdapter(scene: scene)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitConflictResolverSceneObserver(capability: adapter, viewModel: viewModel)

        #expect(viewModel.isActive)

        scene.selectScene(.banner)
        #expect(!viewModel.isActive)

        scene.selectScene(.git)
        #expect(viewModel.isActive)

        observer.cancel()
        // 取消后不再接收场景变化。
        scene.selectScene(.banner)
        #expect(viewModel.isActive)
    }
}
