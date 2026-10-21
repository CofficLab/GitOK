import Foundation
import GitOKProviderRootView
import KernelCore
import KitGit
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI
import Testing
@testable import PluginGitConflictResolver

/// `GitConflictResolverPlugin` 贡献内容的构造与冲突标记识别的补充覆盖。
///
/// - 状态栏项 / 根视图叠层的视图构造闭包只有被真正构造一次才会执行；
/// - `containsConflictMarkers` 只有在冲突文件真实存在时才会走到扫描分支。
@MainActor
@Suite("GitConflictResolverPlugin 补充覆盖")
struct ConflictResolverPluginSupplementalTests {

    // MARK: - Helpers

    private func makeKernel() throws -> (
        kernel: KernelCoreContainer,
        statusBar: TestStatusBarProviding,
        projects: TestProjectsProviding,
        scene: TestSceneProviding,
        rootView: DefaultRootViewProvider
    ) {
        let kernel = KernelCoreContainer()
        let statusBar = TestStatusBarProviding()
        let projects = TestProjectsProviding()
        let scene = TestSceneProviding()
        let rootView = DefaultRootViewProvider()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, projects)
        try kernel.registerProvider((any GitProviding).self, TestGitProviding())
        try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        try kernel.registerProvider((any RootViewProviding).self, rootView)
        return (kernel, statusBar, projects, scene, rootView)
    }

    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitConflictResolverTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    // MARK: - 贡献内容可构造

    @Test("状态栏项与根视图叠层的视图可以被构造")
    func contributedViewsCanBeConstructed() throws {
        let (kernel, statusBar, _, _, rootView) = try makeKernel()
        let plugin = GitConflictResolverPlugin()
        try plugin.onBoot(kernel: kernel)
        defer { try? plugin.onShutdown(kernel: kernel) }

        let item = try #require(statusBar.statusBarItems.first)
        let statusBarView = item.makeView()
        #expect(type(of: statusBarView) == AnyView.self)

        let overlay = try #require(rootView.overlays.first)
        let wrapped = overlay.wrap(AnyView(EmptyView()))
        #expect(type(of: wrapped) == AnyView.self)
    }

    // MARK: - 冲突标记识别

    @Test("带冲突标记的文件不算已解决，无标记的文件算已解决")
    func conflictMarkersAreDetectedInRealFiles() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try """
        <<<<<<< HEAD
        ours
        =======
        theirs
        >>>>>>> feature
        """.write(
            to: directory.appendingPathComponent("conflicted.txt"),
            atomically: true,
            encoding: .utf8
        )
        try "clean content\n".write(
            to: directory.appendingPathComponent("clean.txt"),
            atomically: true,
            encoding: .utf8
        )

        let git = TestGitProviding()
        git.conflictFilesStub = ["conflicted.txt", "clean.txt"]
        git.isMergingStub = true

        let capability = TestConflictResolverCapability()
        capability.currentProject = Project(url: directory)
        let viewModel = GitConflictResolverViewModel()
        let observer = GitConflictResolverObserver(
            capability: capability,
            git: git,
            viewModel: viewModel
        )
        defer { observer.cancel() }

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, viewModel.resolvedConflictFiles.isEmpty {
            await Task.yield()
        }

        // 带标记的文件仍在冲突列表里；干净文件已经算作已解决。
        #expect(viewModel.conflictedFiles == ["conflicted.txt", "clean.txt"])
        #expect(viewModel.resolvedConflictFiles == ["clean.txt"])
    }

    @Test("冲突文件不存在时按未解决处理")
    func missingConflictFileStaysUnresolved() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let git = TestGitProviding()
        git.conflictFilesStub = ["missing.txt"]
        git.isMergingStub = true

        let capability = TestConflictResolverCapability()
        capability.currentProject = Project(url: directory)
        let viewModel = GitConflictResolverViewModel()
        let observer = GitConflictResolverObserver(
            capability: capability,
            git: git,
            viewModel: viewModel
        )
        defer { observer.cancel() }

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, viewModel.hasLoadedSnapshot == false {
            await Task.yield()
        }

        #expect(viewModel.conflictedFiles == ["missing.txt"])
        #expect(viewModel.resolvedConflictFiles.isEmpty)
    }

    // MARK: - 与冲突状态无关的项目事件

    @Test("会话级项目事件不会触发重新读取")
    func sessionScopedProjectEventDoesNotReload() async throws {
        let url = URL(fileURLWithPath: "/tmp/obs-session-event")
        let git = TestGitProviding()
        git.conflictFilesStub = ["a.txt"]
        git.isMergingStub = true

        let capability = TestConflictResolverCapability()
        capability.currentProject = Project(url: url)
        let viewModel = GitConflictResolverViewModel()
        let observer = GitConflictResolverObserver(
            capability: capability,
            git: git,
            viewModel: viewModel
        )
        defer { observer.cancel() }

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, viewModel.hasLoadedSnapshot == false {
            await Task.yield()
        }
        let readsAfterInit = git.conflictFileReadCount

        capability.sendProjectEvent(.commitSelectionChanged)
        capability.sendProjectEvent(.currentFileChanged)
        await Task.yield()

        #expect(git.conflictFileReadCount == readsAfterInit, "会话级事件不应重新读取仓库")
    }
}
