import Foundation
import KernelCore
import KitGit
import ProviderDocsView
import ProviderGit
import ProviderProjects
import ProviderStatusBar
import ProviderStorage
import ProviderWorkspaceScene
import SwiftUI
import Testing
@testable import PluginGitSmartMerge

// MARK: - Tests

/// `GitSmartMergePlugin` 的生命周期接线覆盖。
@Suite("GitSmartMergePlugin 接线")
@MainActor
struct GitSmartMergePluginWiringTests {

    private func makeKernel(
        withStatusBar: Bool = true,
        withProjects: Bool = true,
        withGit: Bool = true,
        withScene: Bool = true,
        withStorage: Bool = true,
        withDocs: Bool = false
    ) throws -> (
        kernel: KernelCoreContainer,
        statusBar: GitSmartMergeDoubles.StatusBar,
        scene: GitSmartMergeDoubles.Scene,
        docs: DefaultDocsViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let statusBar = GitSmartMergeDoubles.StatusBar()
        let scene = GitSmartMergeDoubles.Scene()
        let docs = DefaultDocsViewProviding()
        if withStatusBar {
            try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, GitSmartMergeDoubles.Projects())
        }
        if withGit {
            try kernel.registerProvider((any GitProviding).self, GitSmartMergeDoubles.Git())
        }
        if withScene {
            try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        }
        if withStorage {
            let storage = DefaultStorageProvider(
                dataRootDirectory: FileManager.default.temporaryDirectory
                    .appendingPathComponent("GitSmartMerge-\(UUID().uuidString)", isDirectory: true)
            )
            try kernel.registerProvider((any StorageProviding).self, storage)
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
        let plugin = GitSmartMergePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any StatusBarProviding).self) == nil)
    }

    @Test("缺少项目提供方时不注册状态栏项")
    func bootWithoutProjects() throws {
        let (kernel, statusBar, _, _) = try makeKernel(withProjects: false)
        let plugin = GitSmartMergePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    @Test("缺少 Git 提供方时不注册状态栏项")
    func bootWithoutGit() throws {
        let (kernel, statusBar, _, _) = try makeKernel(withGit: false)
        let plugin = GitSmartMergePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    @Test("缺少场景提供方时不注册状态栏项")
    func bootWithoutScene() throws {
        let (kernel, statusBar, _, _) = try makeKernel(withScene: false)
        let plugin = GitSmartMergePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - 注入与撤回

    @Test("依赖齐备时注册 trailing 状态栏项并订阅场景")
    func bootRegistersStatusBarItem() throws {
        let (kernel, statusBar, scene, _) = try makeKernel()
        let plugin = GitSmartMergePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.count == 1)
        let item = try #require(statusBar.statusBarItems.first)
        #expect(item.id == GitSmartMergePlugin.itemID)
        #expect(item.placement == .trailing)
        #expect(item.order == 24)
        #expect(item.title.isEmpty == false)
        #expect(scene.observerCount == 1)
    }

    @Test("状态栏项可以构造出贡献视图")
    func statusBarItemBuildsView() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = GitSmartMergePlugin()

        try plugin.onBoot(kernel: kernel)

        let item = try #require(statusBar.statusBarItems.first)
        let view = item.makeView()
        #expect(type(of: view) == AnyView.self)
    }

    @Test("onShutdown 撤回状态栏项并取消场景订阅")
    func shutdownRemovesStatusBarItem() throws {
        let (kernel, statusBar, scene, _) = try makeKernel()
        let plugin = GitSmartMergePlugin()
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        #expect(scene.observerCount == 0)
    }

    @Test("未启动就卸载是安全的")
    func shutdownWithoutBoot() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = GitSmartMergePlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - onRegister / onUnregister

    @Test("onRegister 挂载「关于」条目，onUnregister 撤回")
    func registerAndUnregisterAboutEntry() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = GitSmartMergePlugin()

        try plugin.onRegister(kernel: kernel)
        #expect(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        #expect(!docs.aboutEntries.contains { $0.id == plugin.id })
    }

    @Test("关于条目可以构造出视图")
    func aboutEntryBuildsView() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = GitSmartMergePlugin()

        try plugin.onRegister(kernel: kernel)

        let entry = try #require(docs.aboutEntries.first { $0.id == plugin.id })
        let view = entry.makeView()
        #expect(type(of: view) == AnyView.self)
    }

    @Test("没有文档提供方时 onRegister / onUnregister 也不抛错")
    func registerWithoutDocsProvider() throws {
        let (kernel, _, _, _) = try makeKernel(withDocs: false)
        let plugin = GitSmartMergePlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - kernel.start

    @Test("可通过 kernel.start 启动并注册状态栏项")
    func startViaKernel() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = GitSmartMergePlugin()

        try kernel.start(plugins: [plugin])

        #expect(kernel.isPluginRegistered(id: plugin.id))
        #expect(statusBar.statusBarItems.count == 1)
        try kernel.stop()
    }

    // MARK: - 场景能力与观察者

    @Test("场景能力适配器透传当前场景并转发订阅")
    func sceneCapabilityAdapterForwardsScene() throws {
        let scene = GitSmartMergeDoubles.Scene()
        let adapter = GitSmartMergeSceneCapabilityAdapter(scene: scene)

        #expect(adapter.currentScene == .git)

        var received: [WorkspaceSceneEvent] = []
        let handle = adapter.addObserver { received.append($0) }
        scene.selectScene(.banner)
        #expect(received.count == 1)
        handle.cancel()
    }

    @Test("场景观察者把场景变化写入可见性 ViewModel")
    func sceneObserverUpdatesVisibilityViewModel() throws {
        let scene = GitSmartMergeDoubles.Scene()
        let adapter = GitSmartMergeSceneCapabilityAdapter(scene: scene)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitSmartMergeSceneObserver(capability: adapter, viewModel: viewModel)

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
