import Foundation
import KitGit
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects
import Testing
@testable import PluginGitBranchStatus

/// `GitBranchStatusCapability` 的可控替身。
@MainActor
final class BranchStatusCapabilityMock: GitBranchStatusCapability {
    var currentProject: Project?
    var supportsRepositoryObservers = true

    private(set) var projectHandles: [BranchStatusMockHandle] = []
    private(set) var repositoryHandles: [BranchStatusMockHandle] = []
    private var projectCallbacks: [(handle: BranchStatusMockHandle, callback: (ProjectProvidingEvent) -> Void)] = []
    private var repositoryCallbacks: [(handle: BranchStatusMockHandle, callback: (GitRepositoryWatchingEvent) -> Void)] = []

    func addProjectObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        let handle = BranchStatusMockHandle()
        projectHandles.append(handle)
        projectCallbacks.append((handle: handle, callback: callback))
        return handle
    }

    func addRepositoryObserver(
        _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
    ) -> (any GitRepositoryWatchingObserverHandle)? {
        guard supportsRepositoryObservers else { return nil }
        let handle = BranchStatusMockHandle()
        repositoryHandles.append(handle)
        repositoryCallbacks.append((handle: handle, callback: callback))
        return handle
    }

    func sendProjectEvent(_ event: ProjectProvidingEvent) {
        for entry in projectCallbacks where !entry.handle.isCancelled {
            entry.callback(event)
        }
    }

    func sendRepositoryEvent(_ event: GitRepositoryWatchingEvent) {
        for entry in repositoryCallbacks where !entry.handle.isCancelled {
            entry.callback(event)
        }
    }
}

/// 记录 `cancel()` 是否被调用的观察句柄。
@MainActor
final class BranchStatusMockHandle: ProjectProvidingObserverHandle, GitRepositoryWatchingObserverHandle {
    private(set) var isCancelled = false
    func cancel() { isCancelled = true }
}

/// `GitBranchStatusObserver` 的行为测试。
@MainActor
@Suite("GitBranchStatusObserver")
struct GitBranchStatusObserverTests {

    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitBranchStatusObserverTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            await Task.yield()
        }
        return condition()
    }

    private func makeObserver(
        projectURL: URL?,
        git: BranchStatusGitProviding
    ) -> (
        observer: GitBranchStatusObserver,
        viewModel: GitBranchStatusViewModel,
        capability: BranchStatusCapabilityMock
    ) {
        let capability = BranchStatusCapabilityMock()
        capability.currentProject = projectURL.map { Project(url: $0) }
        let viewModel = GitBranchStatusViewModel()
        let observer = GitBranchStatusObserver(
            capability: capability,
            git: git,
            viewModel: viewModel
        )
        return (observer, viewModel, capability)
    }

    // MARK: - 初始加载

    @Test("没有当前项目时清空状态")
    func noProjectClearsState() async {
        let git = BranchStatusGitProviding()
        let (observer, viewModel, _) = makeObserver(projectURL: nil, git: git)
        defer { observer.cancel() }

        #expect(viewModel.currentProjectURL == nil)
        #expect(viewModel.currentBranch == nil)
        #expect(!viewModel.isLoading)
    }

    @Test("项目路径不存在时清空状态")
    func missingProjectDirectoryClearsState() async {
        let git = BranchStatusGitProviding()
        let missing = URL(fileURLWithPath: "/tmp/branch-status-missing-\(UUID().uuidString)")
        let (observer, viewModel, _) = makeObserver(projectURL: missing, git: git)
        defer { observer.cancel() }

        #expect(viewModel.currentProjectURL == nil)
        #expect(viewModel.currentBranch == nil)
        #expect(!viewModel.isLoading)
    }

    @Test("项目存在时读取当前分支")
    func readsCurrentBranch() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let git = BranchStatusGitProviding()
        git.currentBranchStub = "feature/login"
        let (observer, viewModel, _) = makeObserver(projectURL: directory, git: git)
        defer { observer.cancel() }

        let loaded = await waitUntil { viewModel.currentBranch != nil }
        #expect(loaded)
        #expect(viewModel.currentBranch == "feature/login")
        #expect(viewModel.currentProjectURL == directory)
        #expect(!viewModel.isLoading)
    }

    @Test("仓库没有分支时保持 nil")
    func branchlessRepositoryHasNoBranch() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let git = BranchStatusGitProviding()
        git.currentBranchStub = nil
        let (observer, viewModel, _) = makeObserver(projectURL: directory, git: git)
        defer { observer.cancel() }

        let settled = await waitUntil { viewModel.currentProjectURL != nil }
        #expect(settled)
        #expect(viewModel.currentBranch == nil)
    }

    // MARK: - 事件触发

    @Test("项目选择变化会切到新仓库")
    func projectChangeReloadsBranch() async throws {
        let first = try makeDirectory()
        let second = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }
        let git = BranchStatusGitProviding()
        git.currentBranchStub = "main"
        let (observer, viewModel, capability) = makeObserver(projectURL: first, git: git)
        defer { observer.cancel() }
        _ = await waitUntil { viewModel.currentBranch == "main" }

        git.currentBranchStub = "develop"
        capability.currentProject = Project(url: second)
        capability.sendProjectEvent(.selectionChanged(projectID: UUID()))

        let switched = await waitUntil { viewModel.currentBranch == "develop" }
        #expect(switched)
        #expect(viewModel.currentProjectURL == second)
    }

    @Test("项目数据变化会重新读取分支")
    func dataChangeReloadsBranch() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let git = BranchStatusGitProviding()
        git.currentBranchStub = "main"
        let (observer, viewModel, capability) = makeObserver(projectURL: directory, git: git)
        defer { observer.cancel() }
        _ = await waitUntil { viewModel.currentBranch == "main" }

        git.currentBranchStub = "release"
        capability.sendProjectEvent(.dataChanged)

        let reloaded = await waitUntil { viewModel.currentBranch == "release" }
        #expect(reloaded)
    }

    @Test("会话级项目事件不触发刷新")
    func sessionScopedProjectEventDoesNotReload() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let git = BranchStatusGitProviding()
        git.currentBranchStub = "main"
        let (observer, viewModel, capability) = makeObserver(projectURL: directory, git: git)
        defer { observer.cancel() }
        _ = await waitUntil { viewModel.currentBranch == "main" }

        git.currentBranchStub = "never-applied"
        capability.sendProjectEvent(.commitSelectionChanged)
        capability.sendProjectEvent(.currentFileChanged)
        await Task.yield()

        #expect(viewModel.currentBranch == "main")
    }

    @Test("仓库 HEAD 与 refs 变化会重新读取分支")
    func repositoryEventsReloadBranch() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let git = BranchStatusGitProviding()
        git.currentBranchStub = "main"
        let (observer, viewModel, capability) = makeObserver(projectURL: directory, git: git)
        defer { observer.cancel() }
        _ = await waitUntil { viewModel.currentBranch == "main" }

        git.currentBranchStub = "hotfix"
        capability.sendRepositoryEvent(.headChanged(previousHead: "a", head: "b"))

        let reloaded = await waitUntil { viewModel.currentBranch == "hotfix" }
        #expect(reloaded)
    }

    @Test("与分支无关的仓库事件不触发刷新")
    func unrelatedRepositoryEventDoesNotReload() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let git = BranchStatusGitProviding()
        git.currentBranchStub = "main"
        let (observer, viewModel, capability) = makeObserver(projectURL: directory, git: git)
        defer { observer.cancel() }
        _ = await waitUntil { viewModel.currentBranch == "main" }

        git.currentBranchStub = "never-applied"
        capability.sendRepositoryEvent(.indexChanged)
        capability.sendRepositoryEvent(.stashChanged)
        capability.sendRepositoryEvent(.workingTreeChanged)
        await Task.yield()

        #expect(viewModel.currentBranch == "main")
    }

    @Test("没有注册仓库监听时仍可工作")
    func worksWithoutRepositoryObserver() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let git = BranchStatusGitProviding()
        git.currentBranchStub = "main"
        let capability = BranchStatusCapabilityMock()
        capability.supportsRepositoryObservers = false
        capability.currentProject = Project(url: directory)
        let viewModel = GitBranchStatusViewModel()
        let observer = GitBranchStatusObserver(
            capability: capability,
            git: git,
            viewModel: viewModel
        )
        defer { observer.cancel() }

        #expect(capability.repositoryHandles.isEmpty)
        let loaded = await waitUntil { viewModel.currentBranch == "main" }
        #expect(loaded)
    }

    // MARK: - 生命周期

    @Test("cancel 会解除观察")
    func cancelReleasesObservers() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let git = BranchStatusGitProviding()
        git.currentBranchStub = "main"
        let (observer, viewModel, capability) = makeObserver(projectURL: directory, git: git)
        _ = await waitUntil { viewModel.currentBranch == "main" }

        observer.cancel()

        #expect(capability.projectHandles.allSatisfy { $0.isCancelled })
        #expect(capability.repositoryHandles.allSatisfy { $0.isCancelled })

        // 取消后事件不再触发刷新。
        git.currentBranchStub = "never-applied"
        capability.sendProjectEvent(.dataChanged)
        await Task.yield()
        #expect(viewModel.currentBranch == "main")
    }
}
