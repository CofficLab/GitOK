import Foundation
import KernelCore
import KitGit
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI
import Testing
@testable import PluginFileInfo

/// 覆盖 `FileInfoPlugin` 的依赖守卫链与状态栏项注入 / 撤回。
@MainActor
@Suite("PluginFileInfo 生命周期")
struct FileInfoPluginLifecycleTests {

    // MARK: - Helpers

    private func makeKernel(
        withStatusBar: Bool = true,
        withProjects: Bool = true,
        withScene: Bool = true
    ) throws -> (kernel: KernelCoreContainer, statusBar: DefaultStatusBarProviding, scene: DefaultWorkspaceSceneProvider) {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        let scene = DefaultWorkspaceSceneProvider()
        if withStatusBar {
            try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, FileInfoTestsProjects())
        }
        if withScene {
            try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        }
        return (kernel, statusBar, scene)
    }

    // MARK: - 守卫链

    @Test("缺少 StatusBarProviding 时不注入状态栏项")
    func onBootWithoutStatusBarInjectsNothing() throws {
        let (kernel, _, _) = try makeKernel(withStatusBar: false)
        let plugin = FileInfoPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any StatusBarProviding).self) == nil)
    }

    @Test("缺少 ProjectProviding 时不注入状态栏项")
    func onBootWithoutProjectsInjectsNothing() throws {
        let (kernel, statusBar, _) = try makeKernel(withProjects: false)
        let plugin = FileInfoPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    @Test("缺少 WorkspaceSceneProviding 时不注入状态栏项")
    func onBootWithoutSceneInjectsNothing() throws {
        let (kernel, statusBar, _) = try makeKernel(withScene: false)
        let plugin = FileInfoPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - 注入与撤回

    @Test("依赖齐备时注入 leading 状态栏项")
    func onBootInjectsStatusBarItem() throws {
        let (kernel, statusBar, _) = try makeKernel()
        let plugin = FileInfoPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.count == 1)
        let item = statusBar.statusBarItems.first
        #expect(item?.id == FileInfoPlugin.itemID)
        #expect(item?.placement == .leading)
        #expect(item?.order == 19)
    }

    @Test("onShutdown 撤回状态栏项")
    func onShutdownRemovesStatusBarItem() throws {
        let (kernel, statusBar, _) = try makeKernel()
        let plugin = FileInfoPlugin()

        try plugin.onBoot(kernel: kernel)
        #expect(statusBar.statusBarItems.count == 1)

        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    @Test("onShutdown 保留其它插件注入的状态栏项")
    func onShutdownKeepsForeignItems() throws {
        let (kernel, statusBar, _) = try makeKernel()
        statusBar.addStatusBarItems([
            StatusBarItem(id: "com.example.other", title: "Other", placement: .trailing) { EmptyView() },
        ])
        let plugin = FileInfoPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.map(\.id) == ["com.example.other"])
    }

    @Test("缺少 StatusBarProviding 时 onShutdown 不抛异常")
    func onShutdownWithoutStatusBarIsNoOp() throws {
        let (kernel, _, _) = try makeKernel(withStatusBar: false)
        let plugin = FileInfoPlugin()

        try plugin.onShutdown(kernel: kernel)
    }
}

// MARK: - Test Doubles

/// `ProjectProviding` 的最小替身：生命周期测试只关心依赖是否可解析。
@MainActor
final class FileInfoTestsProjects: ProjectProviding {
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
        FileInfoTestsProjectHandle()
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
final class FileInfoTestsProjectHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}
