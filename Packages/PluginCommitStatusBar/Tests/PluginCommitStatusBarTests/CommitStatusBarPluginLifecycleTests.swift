import Foundation
import KernelCore
import KitGit
import ProviderDocsView
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import XCTest
@testable import PluginCommitStatusBar

/// `CommitStatusBarPlugin` 的生命周期接线与场景观察覆盖。
///
/// 插件在 `onBoot` 里解析状态栏 / 项目 / 场景三个依赖，向状态栏注入
/// 「Selected Commit」项，并把场景变化写入自己的可见性 ViewModel；
/// `onShutdown` 取消场景订阅并撤回状态栏项。
@MainActor
final class CommitStatusBarPluginLifecycleTests: XCTestCase {

    // MARK: - Helpers

    private func makeKernel(
        withStatusBar: Bool = true,
        withProjects: Bool = true,
        withScene: Bool = true,
        withDocs: Bool = false
    ) throws -> (
        kernel: KernelCoreContainer,
        statusBar: DefaultStatusBarProviding,
        scene: DefaultWorkspaceSceneProvider,
        docs: DefaultDocsViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        let scene = DefaultWorkspaceSceneProvider()
        let docs = DefaultDocsViewProviding()
        if withStatusBar {
            try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        }
        if withProjects {
            try kernel.registerProvider(
                (any ProjectProviding).self,
                CommitStatusBarPluginTestsProjects()
            )
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

    func testOnBootWithoutStatusBarDoesNotRegisterItem() throws {
        let (kernel, _, _, _) = try makeKernel(withStatusBar: false)
        let plugin = CommitStatusBarPlugin()

        try plugin.onBoot(kernel: kernel)

        XCTAssertNil(kernel.resolveProvider((any StatusBarProviding).self))
    }

    func testOnBootWithoutProjectsDoesNotRegisterItem() throws {
        let (kernel, statusBar, _, _) = try makeKernel(withProjects: false)
        let plugin = CommitStatusBarPlugin()

        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(statusBar.statusBarItems.isEmpty)
    }

    func testOnBootWithoutSceneDoesNotRegisterItem() throws {
        let (kernel, statusBar, _, _) = try makeKernel(withScene: false)
        let plugin = CommitStatusBarPlugin()

        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - 注入与撤回

    func testOnBootRegistersLeadingStatusBarItem() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = CommitStatusBarPlugin()

        try plugin.onBoot(kernel: kernel)

        let item = statusBar.statusBarItems.first { $0.id == CommitStatusBarPlugin.itemID }
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.placement, .leading)
        XCTAssertEqual(item?.order, 20)
    }

    func testOnShutdownRemovesStatusBarItem() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = CommitStatusBarPlugin()
        try plugin.onBoot(kernel: kernel)
        XCTAssertFalse(statusBar.statusBarItems.isEmpty)

        try plugin.onShutdown(kernel: kernel)

        XCTAssertTrue(statusBar.statusBarItems.isEmpty)
    }

    func testOnShutdownWithoutBootIsSafe() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = CommitStatusBarPlugin()

        try plugin.onShutdown(kernel: kernel)

        XCTAssertTrue(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - onRegister / onUnregister

    func testOnRegisterAddsAboutEntryAndOnUnregisterRemovesIt() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = CommitStatusBarPlugin()

        try plugin.onRegister(kernel: kernel)
        XCTAssertTrue(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        XCTAssertFalse(docs.aboutEntries.contains { $0.id == plugin.id })
    }

    func testOnRegisterWithoutDocsProviderIsSafe() throws {
        let (kernel, _, _, _) = try makeKernel(withDocs: false)
        let plugin = CommitStatusBarPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - kernel.start

    func testStartViaKernelSkipsDisabledPolicy() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = CommitStatusBarPlugin()
        XCTAssertEqual(plugin.metadata.policy, .disabled)

        try kernel.start(plugins: [plugin])

        // KernelCore 会彻底排除策略为 .disabled 的插件：不注册、不启动。
        XCTAssertFalse(kernel.isPluginRegistered(id: plugin.id))
        XCTAssertTrue(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - 场景能力与观察者

    func testSceneCapabilityAdapterForwardsCurrentSceneAndEvents() throws {
        let scene = DefaultWorkspaceSceneProvider()
        let adapter = CommitStatusBarSceneCapabilityAdapter(scene: scene)

        XCTAssertEqual(adapter.currentScene, .git)

        var received: [WorkspaceSceneEvent] = []
        let handle = adapter.addObserver { received.append($0) }
        scene.selectScene(.banner)
        XCTAssertEqual(received.count, 1)
        handle.cancel()
    }

    func testSceneObserverUpdatesVisibilityViewModel() throws {
        let scene = DefaultWorkspaceSceneProvider()
        let adapter = CommitStatusBarSceneCapabilityAdapter(scene: scene)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = CommitStatusBarSceneObserver(capability: adapter, viewModel: viewModel)

        XCTAssertTrue(viewModel.isActive)

        scene.selectScene(.banner)
        XCTAssertFalse(viewModel.isActive)

        scene.selectScene(.git)
        XCTAssertTrue(viewModel.isActive)

        observer.cancel()
        scene.selectScene(.banner)
        XCTAssertTrue(viewModel.isActive, "取消订阅后不应再收到场景变化")
    }
}

/// `ProjectProviding` 的最小替身：生命周期测试只关心依赖是否可解析。
@MainActor
final class CommitStatusBarPluginTestsProjects: ProjectProviding {
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
        CommitStatusBarPluginTestsHandle()
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
final class CommitStatusBarPluginTestsHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}
