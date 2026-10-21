import Foundation
import KernelCore
import KitGit
import ProviderDocsView
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderToolbar
import ProviderWorkspaceScene
import Testing
@testable import PluginGitBranchStatus

/// `GitBranchStatusPlugin` 的生命周期接线与分支观察覆盖。
///
/// 插件在 `onBoot` 里解析项目 / Git / 场景三个依赖，向工具栏注入分支选择器，
/// 并把项目选择变化与仓库 HEAD/refs 变化映射成「当前分支」刷新。
@MainActor
@Suite("GitBranchStatusPlugin lifecycle")
struct GitBranchStatusPluginLifecycleTests {

    // MARK: - Helpers

    private struct Harness {
        let kernel: KernelCoreContainer
        let projects: BranchStatusProjectsProviding
        let git: BranchStatusGitProviding
        let scene: BranchStatusSceneProviding
        let toolbar: DefaultToolbarProviding
        let repositoryWatch: BranchStatusRepositoryWatching
        let docs: DefaultDocsViewProviding
    }

    private func makeHarness(
        withProjects: Bool = true,
        withGit: Bool = true,
        withScene: Bool = true,
        withToolbar: Bool = true,
        withRepositoryWatch: Bool = false,
        withDocs: Bool = false
    ) throws -> Harness {
        let kernel = KernelCoreContainer()
        let projects = BranchStatusProjectsProviding()
        let git = BranchStatusGitProviding()
        let scene = BranchStatusSceneProviding()
        let toolbar = DefaultToolbarProviding()
        let repositoryWatch = BranchStatusRepositoryWatching()
        let docs = DefaultDocsViewProviding()
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, projects)
        }
        if withGit {
            try kernel.registerProvider((any GitProviding).self, git)
        }
        if withScene {
            try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        }
        if withToolbar {
            try kernel.registerProvider((any ToolbarProviding).self, toolbar)
        }
        if withRepositoryWatch {
            try kernel.registerProvider((any GitRepositoryWatching).self, repositoryWatch)
        }
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return Harness(
            kernel: kernel,
            projects: projects,
            git: git,
            scene: scene,
            toolbar: toolbar,
            repositoryWatch: repositoryWatch,
            docs: docs
        )
    }

    /// 构造一个真实存在的目录（observer 要求项目路径存在才会读取分支）。
    private func makeExistingDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitBranchStatusTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    // MARK: - 守卫链

    @Test("缺少项目提供方时不注册工具栏项")
    func bootWithoutProjects() throws {
        let harness = try makeHarness(withProjects: false)
        let plugin = GitBranchStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.toolbar.toolbarItems.isEmpty)
    }

    @Test("缺少 Git 提供方时不注册工具栏项")
    func bootWithoutGit() throws {
        let harness = try makeHarness(withGit: false)
        let plugin = GitBranchStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.toolbar.toolbarItems.isEmpty)
    }

    @Test("缺少场景提供方时不注册工具栏项")
    func bootWithoutScene() throws {
        let harness = try makeHarness(withScene: false)
        let plugin = GitBranchStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.toolbar.toolbarItems.isEmpty)
    }

    @Test("缺少工具栏提供方时其余接线仍可完成")
    func bootWithoutToolbar() throws {
        let harness = try makeHarness(withToolbar: false)
        let plugin = GitBranchStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.toolbar.toolbarItems.isEmpty)
    }

    // MARK: - 注入与撤回

    @Test("依赖齐备时注册 trailing 工具栏项并订阅场景")
    func bootRegistersToolbarItem() throws {
        let harness = try makeHarness()
        let plugin = GitBranchStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.toolbar.toolbarItems.count == 1)
        let item = try #require(harness.toolbar.toolbarItems.first)
        #expect(item.id == GitBranchStatusPlugin.toolbarItemID)
        #expect(item.placement == .trailing)
        #expect(item.category == .project)
        #expect(item.order == -50)
        #expect(harness.scene.observerCount == 1)
    }

    @Test("onShutdown 撤回工具栏项并取消场景订阅")
    func shutdownRemovesToolbarItem() throws {
        let harness = try makeHarness()
        let plugin = GitBranchStatusPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        #expect(harness.toolbar.toolbarItems.count == 1)

        try plugin.onShutdown(kernel: harness.kernel)

        #expect(harness.toolbar.toolbarItems.isEmpty)
        #expect(harness.scene.observerCount == 0)
    }

    @Test("未启动就卸载是安全的")
    func shutdownWithoutBoot() throws {
        let harness = try makeHarness()
        let plugin = GitBranchStatusPlugin()

        try plugin.onShutdown(kernel: harness.kernel)

        #expect(harness.toolbar.toolbarItems.isEmpty)
    }

    // MARK: - onRegister / onUnregister

    @Test("onRegister 挂载「关于」条目，onUnregister 撤回")
    func registerAndUnregisterAboutEntry() throws {
        let harness = try makeHarness(withDocs: true)
        let plugin = GitBranchStatusPlugin()

        try plugin.onRegister(kernel: harness.kernel)
        #expect(harness.docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: harness.kernel)
        #expect(!harness.docs.aboutEntries.contains { $0.id == plugin.id })
    }

    @Test("没有文档提供方时 onRegister / onUnregister 也不抛错")
    func registerWithoutDocsProvider() throws {
        let harness = try makeHarness(withDocs: false)
        let plugin = GitBranchStatusPlugin()

        try plugin.onRegister(kernel: harness.kernel)
        try plugin.onUnregister(kernel: harness.kernel)
    }

    // MARK: - kernel.start

    @Test("可通过 kernel.start 启动并注册工具栏项")
    func startViaKernel() throws {
        let harness = try makeHarness()
        let plugin = GitBranchStatusPlugin()

        try harness.kernel.start(plugins: [plugin])

        #expect(harness.kernel.isPluginRegistered(id: plugin.id))
        #expect(harness.toolbar.toolbarItems.count == 1)
        try harness.kernel.stop()
    }

    // MARK: - 能力适配器

    @Test("项目能力适配器透传当前项目并转发订阅")
    func capabilityAdapterForwardsProjectState() throws {
        let projects = BranchStatusProjectsProviding()
        let url = URL(fileURLWithPath: "/tmp/branch-project")
        projects.currentProject = Project(url: url)
        let adapter = GitBranchStatusCapabilityAdapter(projects: projects, gitWatch: nil)

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
        let scene = BranchStatusSceneProviding(currentScene: .git)
        let adapter = GitBranchStatusSceneCapabilityAdapter(scene: scene)

        #expect(adapter.currentScene == .git)

        var received: [WorkspaceSceneEvent] = []
        let handle = adapter.addObserver { received.append($0) }
        scene.selectScene(.banner)
        #expect(received.count == 1)
        handle.cancel()
    }

    @Test("场景观察者把场景变化写入可见性 ViewModel")
    func sceneObserverUpdatesVisibilityViewModel() throws {
        let scene = BranchStatusSceneProviding(currentScene: .git)
        let adapter = GitBranchStatusSceneCapabilityAdapter(scene: scene)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitBranchStatusSceneObserver(capability: adapter, viewModel: viewModel)

        #expect(viewModel.isActive)

        scene.selectScene(.banner)
        #expect(!viewModel.isActive)

        scene.selectScene(.git)
        #expect(viewModel.isActive)

        observer.cancel()
        scene.selectScene(.banner)
        #expect(viewModel.isActive)
    }
}
