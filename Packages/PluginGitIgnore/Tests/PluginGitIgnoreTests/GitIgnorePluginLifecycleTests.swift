import Foundation
import KernelCore
import KitGit
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI
import Testing

@testable import PluginGitIgnore

// MARK: - Test Doubles

/// 记录插件写入状态栏项的最小 `StatusBarProviding` 替身。
@MainActor
private final class MockStatusBarProvider: StatusBarProviding, ObservableObject {
    var statusBarItems: [StatusBarItem] = []

    func registerStatusBarItems(_ items: [StatusBarItem]) {
        statusBarItems = items
    }

    func makeStatusBarView() -> AnyView { AnyView(EmptyView()) }
}

/// 可手动派发场景事件的 `WorkspaceSceneProviding` 替身。
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

/// 满足 `ProjectProviding` 全量契约的空实现；本组测试只关心装配是否成功。
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
    ) -> any ProjectProvidingObserverHandle { NoopProjectHandle() }
}

@MainActor
private final class NoopProjectHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}

// MARK: - Tests

@Suite("GitIgnorePlugin 生命周期")
@MainActor
struct GitIgnorePluginLifecycleTests {

    @Test("插件标识与顺序稳定")
    func identity() {
        let plugin = GitIgnorePlugin()

        #expect(plugin.id == "com.coffic.gitok.plugin.git-ignore")
        #expect(plugin.order == 38)
        #expect(plugin.metadata.id == plugin.id)
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.stage == .stable)
        #expect(GitIgnorePlugin.itemID == "com.coffic.gitok.plugin.git-ignore.id")
    }

    @Test("缺少 StatusBarProviding 时 onBoot 安全降级不抛错")
    func bootWithoutStatusBar() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitIgnorePlugin()

        // 无任何 provider 注册时应直接返回，不注册状态栏项。
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("缺少 ProjectProviding 时不注册状态栏项")
    func bootWithoutProjects() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider(StatusBarProviding.self, MockStatusBarProvider())
        let plugin = GitIgnorePlugin()

        try plugin.onBoot(kernel: kernel)

        let statusBar = try #require(kernel.resolveProvider(StatusBarProviding.self))
        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("缺少 WorkspaceSceneProviding 时不注册状态栏项")
    func bootWithoutScene() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        try kernel.registerProvider(StatusBarProviding.self, statusBar)
        try kernel.registerProvider(ProjectProviding.self, StubProjectsProvider())
        let plugin = GitIgnorePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("依赖齐备时注册状态栏项")
    func bootRegistersStatusBarItem() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        let scene = MockSceneProvider()
        try kernel.registerProvider(StatusBarProviding.self, statusBar)
        try kernel.registerProvider(ProjectProviding.self, StubProjectsProvider())
        try kernel.registerProvider(WorkspaceSceneProviding.self, scene)
        let plugin = GitIgnorePlugin()

        try plugin.onBoot(kernel: kernel)

        let item = try #require(statusBar.statusBarItems.first)
        #expect(item.id == GitIgnorePlugin.itemID)
        #expect(statusBar.statusBarItems.count == 1)
        // 装配后已订阅场景事件。
        #expect(scene.observerCount == 1)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("onShutdown 取消场景订阅并移除状态栏项")
    func shutdownCleansUp() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        let scene = MockSceneProvider()
        try kernel.registerProvider(StatusBarProviding.self, statusBar)
        try kernel.registerProvider(ProjectProviding.self, StubProjectsProvider())
        try kernel.registerProvider(WorkspaceSceneProviding.self, scene)
        let plugin = GitIgnorePlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        #expect(scene.observerCount == 0)
    }

    @Test("onShutdown 在从未 boot 时也安全")
    func shutdownWithoutBoot() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        try kernel.registerProvider(StatusBarProviding.self, statusBar)
        let plugin = GitIgnorePlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    @Test("重复 boot 不会产生重复状态栏项")
    func repeatedBootDoesNotDuplicateItems() throws {
        let kernel = KernelCoreContainer()
        let statusBar = MockStatusBarProvider()
        try kernel.registerProvider(StatusBarProviding.self, statusBar)
        try kernel.registerProvider(ProjectProviding.self, StubProjectsProvider())
        try kernel.registerProvider(WorkspaceSceneProviding.self, MockSceneProvider())
        let plugin = GitIgnorePlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.count == 1)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("onRegister / onUnregister 在无 DocsView 时安全降级")
    func registerAndUnregisterWithoutDocs() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitIgnorePlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }
}
