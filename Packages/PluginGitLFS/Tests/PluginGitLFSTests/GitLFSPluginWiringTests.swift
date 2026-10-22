import Foundation
import KernelCore
import KitGit
import ProviderDocsView
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI
import Testing
@testable import PluginGitLFS

// MARK: - Test doubles

/// `ProjectProviding` 的最小替身。
@MainActor
private final class LFSProjectsStub: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?

    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        LFSHandle()
    }

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func moveProject(id: UUID, beforeID: UUID?) {}
    func selectCommit(_ commit: GitCommit) {}
    func selectFile(_ file: String?) {}
    func clearCommitSelection() {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
}

@MainActor
private final class LFSHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}

/// `WorkspaceSceneProviding` 的最小替身：可统计观察者数量。
@MainActor
private final class LFSSceneStub: WorkspaceSceneProviding {
    private(set) var currentScene: GitOKWorkspaceScene = .git
    let availableScenes: [GitOKWorkspaceScene] = GitOKWorkspaceScene.allCases
    private(set) var observerCount = 0
    private var callbacks: [(WorkspaceSceneEvent) -> Void] = []

    func selectScene(_ scene: GitOKWorkspaceScene) {
        guard availableScenes.contains(scene), currentScene != scene else { return }
        let previousScene = currentScene
        currentScene = scene
        let event = WorkspaceSceneEvent.sceneChanged(from: previousScene, to: scene)
        for callback in callbacks {
            callback(event)
        }
    }

    func addObserver(
        _ callback: @escaping (WorkspaceSceneEvent) -> Void
    ) -> any WorkspaceSceneObserverHandle {
        observerCount += 1
        callbacks.append(callback)
        return LFSSceneHandle { [weak self] in
            self?.observerCount -= 1
        }
    }
}

@MainActor
private final class LFSSceneHandle: WorkspaceSceneObserverHandle {
    private var onCancel: (() -> Void)?

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() {
        guard let onCancel else { return }
        self.onCancel = nil
        onCancel()
    }
}

// MARK: - Tests

/// `GitLFSPlugin` 的生命周期接线覆盖。
@Suite("GitLFSPlugin 接线")
@MainActor
struct GitLFSPluginWiringTests {

    private func makeKernel(
        withStatusBar: Bool = true,
        withProjects: Bool = true,
        withScene: Bool = true,
        withDocs: Bool = false
    ) throws -> (
        kernel: KernelCoreContainer,
        statusBar: DefaultStatusBarProviding,
        scene: LFSSceneStub,
        docs: DefaultDocsViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        let scene = LFSSceneStub()
        let docs = DefaultDocsViewProviding()
        if withStatusBar {
            try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, LFSProjectsStub())
        }
        if withScene {
            try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        }
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return (kernel, statusBar, scene, docs)
    }

    // MARK: - 守卫链

    @Test("缺少状态栏时不注册状态栏项")
    func bootWithoutStatusBar() throws {
        let (kernel, _, _, _) = try makeKernel(withStatusBar: false)
        let plugin = GitLFSPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any StatusBarProviding).self) == nil)
    }

    @Test("缺少项目提供方时不注册状态栏项")
    func bootWithoutProjects() throws {
        let (kernel, statusBar, _, _) = try makeKernel(withProjects: false)
        let plugin = GitLFSPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    @Test("缺少场景提供方时不注册状态栏项")
    func bootWithoutScene() throws {
        let (kernel, statusBar, _, _) = try makeKernel(withScene: false)
        let plugin = GitLFSPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - 注入与撤回

    @Test("依赖齐备时注册 leading 状态栏项并订阅场景")
    func bootRegistersStatusBarItem() throws {
        let (kernel, statusBar, scene, _) = try makeKernel()
        let plugin = GitLFSPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.count == 1)
        let item = try #require(statusBar.statusBarItems.first)
        #expect(item.id == GitLFSPlugin.itemID)
        #expect(item.placement == .leading)
        #expect(item.order == 25)
        #expect(scene.observerCount == 1)
    }

    @Test("状态栏项可以构造出贡献视图")
    func statusBarItemBuildsView() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = GitLFSPlugin()

        try plugin.onBoot(kernel: kernel)

        let item = try #require(statusBar.statusBarItems.first)
        let view = item.makeView()
        #expect(type(of: view) == AnyView.self)
    }

    @Test("onShutdown 撤回状态栏项并取消场景订阅")
    func shutdownRemovesStatusBarItem() throws {
        let (kernel, statusBar, scene, _) = try makeKernel()
        let plugin = GitLFSPlugin()
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        #expect(scene.observerCount == 0)
    }

    @Test("未启动就卸载是安全的")
    func shutdownWithoutBoot() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = GitLFSPlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - onRegister / onUnregister

    @Test("onRegister 挂载「关于」条目，onUnregister 撤回")
    func registerAndUnregisterAboutEntry() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = GitLFSPlugin()

        try plugin.onRegister(kernel: kernel)
        #expect(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        #expect(!docs.aboutEntries.contains { $0.id == plugin.id })
    }

    @Test("没有文档提供方时 onRegister / onUnregister 也不抛错")
    func registerWithoutDocsProvider() throws {
        let (kernel, _, _, _) = try makeKernel(withDocs: false)
        let plugin = GitLFSPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - kernel.start

    @Test("策略为 .disabled 的插件不会被 kernel.start 注册")
    func startViaKernelSkipsDisabledPolicy() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = GitLFSPlugin()
        #expect(plugin.metadata.policy == .disabled)

        try kernel.start(plugins: [plugin])

        #expect(kernel.isPluginRegistered(id: plugin.id) == false)
        #expect(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - 场景能力与观察者

    @Test("场景能力适配器透传当前场景并转发订阅")
    func sceneCapabilityAdapterForwardsScene() throws {
        let scene = DefaultWorkspaceSceneProvider()
        let adapter = GitLFSSceneCapabilityAdapter(scene: scene)

        #expect(adapter.currentScene == .git)

        var received: [WorkspaceSceneEvent] = []
        let handle = adapter.addObserver { received.append($0) }
        scene.selectScene(.banner)
        #expect(received.count == 1)
        handle.cancel()
    }

    @Test("场景观察者把场景变化写入可见性 ViewModel")
    func sceneObserverUpdatesVisibilityViewModel() throws {
        let scene = DefaultWorkspaceSceneProvider()
        let adapter = GitLFSSceneCapabilityAdapter(scene: scene)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitLFSSceneObserver(capability: adapter, viewModel: viewModel)

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
