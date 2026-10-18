import Foundation
import KernelCore
import KitGit
import ProviderGit
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import Testing
@testable import PluginGitSubmodule

/// Wiring coverage for `GitSubmodulePlugin`.
///
/// `onBoot` resolves four providers in sequence and bails out on the first
/// missing one, so most of the plugin's branches live in that guard chain.
/// These tests walk the chain one dependency at a time and then verify the
/// scene wiring is torn down again on shutdown.
@Suite("GitSubmodulePlugin wiring")
@MainActor
struct GitSubmodulePluginWiringTests {
    private func makeKernel(
        withStatusBar: Bool = true,
        withProjects: Bool = true,
        withGit: Bool = true,
        withScene: Bool = true
    ) throws -> (
        kernel: KernelCoreContainer,
        statusBar: PluginLifecycleDoubles.StatusBar,
        scene: PluginLifecycleDoubles.Scene
    ) {
        let kernel = KernelCoreContainer()
        let statusBar = PluginLifecycleDoubles.StatusBar()
        let scene = PluginLifecycleDoubles.Scene()
        if withStatusBar {
            try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, PluginLifecycleDoubles.Projects())
        }
        if withGit {
            try kernel.registerProvider((any GitProviding).self, PluginLifecycleDoubles.Git())
        }
        if withScene {
            try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        }
        return (kernel, statusBar, scene)
    }

    // MARK: - Guard chain

    @Test("缺少 ProjectProviding 时不注册状态栏项")
    func bootWithoutProjects() throws {
        let (kernel, statusBar, _) = try makeKernel(withProjects: false)
        let plugin = GitSubmodulePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("缺少 GitProviding 时不注册状态栏项")
    func bootWithoutGit() throws {
        let (kernel, statusBar, _) = try makeKernel(withGit: false)
        let plugin = GitSubmodulePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("缺少 WorkspaceSceneProviding 时不注册状态栏项")
    func bootWithoutScene() throws {
        let (kernel, statusBar, _) = try makeKernel(withScene: false)
        let plugin = GitSubmodulePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    // MARK: - Successful wiring

    @Test("依赖齐备时注册单个状态栏项并订阅场景")
    func bootRegistersStatusBarItem() throws {
        let (kernel, statusBar, scene) = try makeKernel()
        let plugin = GitSubmodulePlugin()

        try plugin.onBoot(kernel: kernel)

        let item = try #require(statusBar.statusBarItems.first)
        #expect(item.id == GitSubmodulePlugin.itemID)
        #expect(statusBar.statusBarItems.count == 1)
        #expect(scene.observerCount == 1)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("onShutdown 取消场景订阅并移除状态栏项")
    func shutdownCleansUp() throws {
        let (kernel, statusBar, scene) = try makeKernel()
        let plugin = GitSubmodulePlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        #expect(scene.observerCount == 0)
    }

    @Test("重复 boot 不产生重复状态栏项")
    func repeatedBootDoesNotDuplicate() throws {
        let (kernel, statusBar, _) = try makeKernel()
        let plugin = GitSubmodulePlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.count == 1)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("重复 shutdown 不会抛错")
    func repeatedShutdownIsSafe() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = GitSubmodulePlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)
    }
}

// MARK: - Scene observer

@Suite("GitSubmoduleSceneObserver")
@MainActor
struct GitSubmoduleSceneObserverTests {
    @Test("初始化时同步当前场景为可见")
    func initialisesWithCurrentScene() {
        let scene = PluginLifecycleDoubles.Scene(currentScene: .git)
        let viewModel = WorkspaceSceneVisibilityViewModel(
            targetScene: .git,
            currentScene: scene.currentScene
        )
        let observer = GitSubmoduleSceneObserver(
            capability: GitSubmoduleSceneCapabilityAdapter(scene: scene),
            viewModel: viewModel
        )

        #expect(viewModel.isActive)
        #expect(scene.observerCount == 1)

        observer.cancel()
    }

    @Test("切换到非目标场景后变为不可见")
    func sceneChangeUpdatesVisibility() {
        let scene = PluginLifecycleDoubles.Scene(currentScene: .git)
        let viewModel = WorkspaceSceneVisibilityViewModel(
            targetScene: .git,
            currentScene: scene.currentScene
        )
        let observer = GitSubmoduleSceneObserver(
            capability: GitSubmoduleSceneCapabilityAdapter(scene: scene),
            viewModel: viewModel
        )
        #expect(viewModel.isActive)

        scene.selectScene(.banner)

        #expect(!viewModel.isActive)
        observer.cancel()
    }

    @Test("切回目标场景后恢复可见")
    func sceneChangeBackRestoresVisibility() {
        let scene = PluginLifecycleDoubles.Scene(currentScene: .git)
        let viewModel = WorkspaceSceneVisibilityViewModel(
            targetScene: .git,
            currentScene: scene.currentScene
        )
        let observer = GitSubmoduleSceneObserver(
            capability: GitSubmoduleSceneCapabilityAdapter(scene: scene),
            viewModel: viewModel
        )

        scene.selectScene(.banner)
        #expect(!viewModel.isActive)

        scene.selectScene(.git)
        #expect(viewModel.isActive)

        observer.cancel()
    }

    @Test("cancel 之后不再响应场景变化")
    func cancelStopsObserving() {
        let scene = PluginLifecycleDoubles.Scene(currentScene: .git)
        let viewModel = WorkspaceSceneVisibilityViewModel(
            targetScene: .git,
            currentScene: scene.currentScene
        )
        let observer = GitSubmoduleSceneObserver(
            capability: GitSubmoduleSceneCapabilityAdapter(scene: scene),
            viewModel: viewModel
        )

        observer.cancel()
        #expect(scene.observerCount == 0)

        scene.selectScene(.banner)
        #expect(viewModel.isActive, "a cancelled observer must not react to later scene changes")
    }

    @Test("重复 cancel 安全")
    func repeatedCancelIsSafe() {
        let scene = PluginLifecycleDoubles.Scene(currentScene: .git)
        let viewModel = WorkspaceSceneVisibilityViewModel(
            targetScene: .git,
            currentScene: scene.currentScene
        )
        let observer = GitSubmoduleSceneObserver(
            capability: GitSubmoduleSceneCapabilityAdapter(scene: scene),
            viewModel: viewModel
        )

        observer.cancel()
        observer.cancel()

        #expect(scene.observerCount == 0)
    }
}
