import Foundation
import KernelCore
import KitGit
import ProviderGit
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI
import Testing
@testable import PluginGitUnpushedStatus

// MARK: - Test doubles

@MainActor
private final class StatusBar: StatusBarProviding, ObservableObject {
    var statusBarItems: [StatusBarItem] = []

    func registerStatusBarItems(_ items: [StatusBarItem]) { statusBarItems = items }

    func makeStatusBarView() -> AnyView { AnyView(EmptyView()) }
}

@MainActor
private final class Scene: WorkspaceSceneProviding {
    var currentScene: GitOKWorkspaceScene
    let availableScenes: [GitOKWorkspaceScene] = [.git, .banner]
    private var subscriptions: [UUID: (WorkspaceSceneEvent) -> Void] = [:]
    private(set) var observerCount = 0

    init(currentScene: GitOKWorkspaceScene = .git) { self.currentScene = currentScene }

    func selectScene(_ scene: GitOKWorkspaceScene) {
        guard scene != currentScene else { return }
        let from = currentScene
        currentScene = scene
        subscriptions.values.forEach { $0(WorkspaceSceneEvent.sceneChanged(from: from, to: scene)) }
    }

    func addObserver(
        _ callback: @escaping (WorkspaceSceneEvent) -> Void
    ) -> any WorkspaceSceneObserverHandle {
        let token = UUID()
        observerCount += 1
        subscriptions[token] = callback
        return SceneHandle { [weak self] in
            self?.subscriptions[token] = nil
            self?.observerCount -= 1
        }
    }
}

@MainActor
private final class SceneHandle: WorkspaceSceneObserverHandle {
    private var cancelAction: (() -> Void)?

    init(cancel: @escaping () -> Void) { self.cancelAction = cancel }

    func cancel() {
        cancelAction?()
        cancelAction = nil
    }
}

@MainActor
private final class Projects: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?
    private var callbacks: [UUID: (ProjectProvidingEvent) -> Void] = [:]
    private(set) var observerCount = 0

    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        let token = UUID()
        observerCount += 1
        callbacks[token] = callback
        return ProjectHandle { [weak self] in
            self?.callbacks[token] = nil
            self?.observerCount -= 1
        }
    }

    func emit(_ event: ProjectProvidingEvent) { callbacks.values.forEach { $0(event) } }

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func moveProject(id: UUID, beforeID: UUID?) {}
    func setCurrentProject(id: UUID?) {}
    func selectCommit(_ commit: GitCommit) { currentCommit = commit }
    func selectFile(_ file: String?) { currentFile = file }
    func clearCommitSelection() { currentCommit = nil; currentFile = nil }
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
}

@MainActor
private final class ProjectHandle: ProjectProvidingObserverHandle {
    private var cancelAction: (() -> Void)?

    init(cancel: @escaping () -> Void) { self.cancelAction = cancel }

    func cancel() {
        cancelAction?()
        cancelAction = nil
    }
}

/// A `GitProviding` whose reads are scriptable; lifecycle suites only need the
/// router type to resolve so `onBoot` can continue past its guards.
final class Git: GitProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: any GitBackendProviding] = [:]
    var availableBackends: [GitBackendDescriptor] { [] }

    /// Unpushed count returned by the backend; `nil` means "no upstream".
    var unpushedCountValue: Int?

    func registerBackend(_ backend: any GitBackendProviding) throws {
        lock.lock(); defer { lock.unlock() }
        storage[backend.descriptor.id] = backend
    }

    func unregisterBackend(id: String) {
        lock.lock(); defer { lock.unlock() }
        storage[id] = nil
    }

    func unpushedCount(in repository: URL) -> Int? { unpushedCountValue }

    func listBranches(in repository: URL) throws -> [GitBranchSummary] { [] }
    func createBranch(named name: String, in repository: URL) throws {}
    func checkoutBranch(named name: String, in repository: URL) throws {}
    func checkoutRemoteBranch(named remoteBranch: String, as localBranch: String?, in repository: URL) throws {}
    func deleteBranch(named name: String, in repository: URL) throws {}
    func renameBranch(from currentName: String, to newName: String, in repository: URL) throws {}
    func setUpstream(localBranch: String, upstreamBranch: String, in repository: URL) throws {}
    func unsetUpstream(localBranch: String, in repository: URL) throws {}
    func publishBranch(localBranch: String, remote: String, remoteBranch: String?, in repository: URL) throws {}
    func deleteRemoteBranch(named branchName: String, remote: String, in repository: URL) throws {}
    func compareBranches(base: String, head: String, in repository: URL) throws -> GitBranchCompare {
        GitBranchCompare(base: base, head: head, ahead: 0, behind: 0, commits: [], files: [])
    }
    func loadCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] { [] }
    func loadAllCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] { [] }
    func countCommits(in repository: URL) throws -> Int { 0 }
    func unpushedCommitHashes(in repository: URL) throws -> Set<String> { [] }
    func loadStatus(in repository: URL) throws -> GitWorktreeStatus {
        GitWorktreeStatus(isClean: true, changeCount: 0, branch: nil)
    }
    func loadEntries(in repository: URL) throws -> [GitStatusEntry] { [] }
    func loadWorktreeSnapshot(in repository: URL) throws -> GitWorktreeSnapshot {
        GitWorktreeSnapshot(entries: [], branch: nil)
    }
    func cachedWorktreeSnapshot(in repository: URL) -> GitWorktreeSnapshot? { nil }
    func invalidateWorktreeSnapshot(in repository: URL) {}
    func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange] { [] }
    func countCommitChanges(commit hash: String, in repository: URL) throws -> Int { 0 }
    func loadCommitChangesPage(commit hash: String, limit: Int, offset: Int, in repository: URL) throws -> GitFileChangePage {
        GitFileChangePage(offset: offset, changes: [], hasMore: false)
    }
    func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String { "" }
    func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String { "" }
    func currentBranch(in repository: URL) -> String? { nil }
    func latestTag(in repository: URL) -> String? { nil }
    func firstCommitDate(in repository: URL) -> Date? { nil }
    func hasRemotes(in repository: URL) -> Bool { false }
    func unpulledCount(in repository: URL) -> Int? { nil }
    func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus {
        GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
    }
    func undoCommit(_ commitHash: String, parentHash: String, in repository: URL) throws -> String { "" }
    func revertCommit(_ commitHash: String, in repository: URL) throws -> String { "" }
    func softReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func mixedReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func hardReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func squash(to targetHash: String, parentHash: String, expectedHead: String, message: String, in repository: URL) throws -> String {
        ""
    }
    func createLightweightTag(named name: String, at commitHash: String, in repository: URL) throws -> String { "" }
    func createAnnotatedTag(named name: String, at commitHash: String, message: String, in repository: URL) throws -> String {
        ""
    }
    func deleteLocalTag(named name: String, in repository: URL) throws -> String { "" }
    func pushTag(named name: String, remote: String, in repository: URL) throws -> String { "" }
    func deleteRemoteTag(named name: String, remote: String, in repository: URL) throws -> String { "" }
    func listStashes(in repository: URL) -> [GitStashEntry] { [] }
    func hasChangesToStash(in repository: URL) -> Bool { false }
    func saveStash(message: String?, in repository: URL) throws {}
    func applyStash(_ entry: GitStashEntry, in repository: URL) throws {}
    func popStash(_ entry: GitStashEntry, in repository: URL) throws {}
    func dropStash(_ entry: GitStashEntry, in repository: URL) throws {}
    func cherryPickStatus(in repository: URL) -> GitCherryPickStatus { .inactive }
    func cherryPick(commits: [String], onto branch: String?, in repository: URL) throws -> String { "" }
    func continueCherryPick(in repository: URL) throws -> String { "" }
    func abortCherryPick(in repository: URL) throws -> String { "" }
    func listSubmodules(in repository: URL) -> [GitSubmoduleSummary] { [] }
    func updateSubmodules(in repository: URL) throws {}
    func validateCloneDestination(_ destination: URL) throws {}
    func defaultRepositoryName(from remoteURL: String) -> String? { nil }
    func clone(remoteURL: String, destination: URL) throws -> URL { destination }
    func hasStagedChanges(in repository: URL) throws -> Bool { false }
    func addAll(in repository: URL) throws {}
    func stageFiles(_ filePaths: [String], in repository: URL) throws {}
    func unstageFiles(_ filePaths: [String], in repository: URL) throws {}
    func discardFileChanges(_ filePath: String, in repository: URL) throws {}
    func discardFiles(_ filePaths: [String], in repository: URL) throws {}
    func discardAllChanges(in repository: URL) throws {}
    func commit(message: String, in repository: URL) throws -> String { "" }
    func push(in repository: URL) throws -> String { "" }
    func listRemotes(in repository: URL) -> [GitRemoteSummary] { [] }
    func addRemote(name: String, url: String, in repository: URL) throws {}
    func removeRemote(name: String, in repository: URL) throws {}
    func fetch(in repository: URL) throws {}
    func pull(in repository: URL) throws {}
    func pull(in repository: URL, strategy: GitRemoteOperation.PullStrategy) throws {}
    func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus {
        GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
    }
    func webLink(for url: String) -> URL? { nil }
    func isMerging(in repository: URL) -> Bool { false }
    func hasConflictOperation(in repository: URL) -> Bool { false }
    func conflictFiles(in repository: URL) -> [String] { [] }
    func mergeBranches(repository: URL, sourceBranch: String, targetBranch: String) throws -> String { "" }
    func mergeFileContent(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String { "" }
    func mergeFileDiff(path: String, in repository: URL) throws -> String { "" }
    func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws {}
    func continueMerge(in repository: URL) throws -> String { "" }
    func abortMerge(in repository: URL) throws -> String { "" }
    func finalizeMergeIfNeeded(in repository: URL) throws -> String? { nil }
}

// MARK: - Lifecycle

/// Wiring coverage for `GitUnpushedStatusPlugin`.
///
/// The plugin resolves four providers in sequence and bails on the first
/// missing one, so most branches live in that guard chain.
@Suite("GitUnpushedStatusPlugin wiring")
@MainActor
struct GitUnpushedStatusPluginWiringTests {
    private func makeKernel(
        withStatusBar: Bool = true,
        withProjects: Bool = true,
        withGit: Bool = true,
        withScene: Bool = true
    ) throws -> (
        kernel: KernelCoreContainer,
        statusBar: StatusBar,
        scene: Scene
    ) {
        let kernel = KernelCoreContainer()
        let statusBar = StatusBar()
        let scene = Scene()
        if withStatusBar {
            try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, Projects())
        }
        if withGit {
            try kernel.registerProvider((any GitProviding).self, Git())
        }
        if withScene {
            try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        }
        return (kernel, statusBar, scene)
    }

    @Test("缺少 StatusBarProviding 时不注册状态栏项")
    func bootWithoutStatusBar() throws {
        let (kernel, statusBar, _) = try makeKernel(withStatusBar: false)
        let plugin = GitUnpushedStatusPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("缺少 ProjectProviding 时不注册状态栏项")
    func bootWithoutProjects() throws {
        let (kernel, statusBar, _) = try makeKernel(withProjects: false)
        let plugin = GitUnpushedStatusPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("缺少 GitProviding 时不注册状态栏项")
    func bootWithoutGit() throws {
        let (kernel, statusBar, _) = try makeKernel(withGit: false)
        let plugin = GitUnpushedStatusPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("缺少 WorkspaceSceneProviding 时不注册状态栏项")
    func bootWithoutScene() throws {
        let (kernel, statusBar, _) = try makeKernel(withScene: false)
        let plugin = GitUnpushedStatusPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("依赖齐备时注册单个状态栏项并订阅场景")
    func bootRegistersStatusBarItem() throws {
        let (kernel, statusBar, scene) = try makeKernel()
        let plugin = GitUnpushedStatusPlugin()

        try plugin.onBoot(kernel: kernel)

        let item = try #require(statusBar.statusBarItems.first)
        #expect(item.id == GitUnpushedStatusPlugin.itemID)
        #expect(statusBar.statusBarItems.count == 1)
        #expect(scene.observerCount == 1)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("onShutdown 取消场景订阅并移除状态栏项")
    func shutdownCleansUp() throws {
        let (kernel, statusBar, scene) = try makeKernel()
        let plugin = GitUnpushedStatusPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        #expect(scene.observerCount == 0)
    }

    @Test("重复 boot 不产生重复状态栏项")
    func repeatedBootDoesNotDuplicate() throws {
        let (kernel, statusBar, _) = try makeKernel()
        let plugin = GitUnpushedStatusPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.count == 1)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("重复 shutdown 不会抛错")
    func repeatedShutdownIsSafe() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = GitUnpushedStatusPlugin()

        try plugin.onShutdown(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)
    }
}

// MARK: - Project observation model

@Suite("ProjectObservationModel")
@MainActor
struct ProjectObservationModelTests {
    @Test("订阅后 observer 计数为 1")
    func subscribesOnInit() {
        let projects = Projects()

        let model = ProjectObservationModel(projects: projects)

        #expect(projects.observerCount == 1)
        #expect(model.revision == 0)
        _ = model
    }

    @Test("仓库级事件推进 revision")
    func repositoryScopedEventsAdvanceRevision() {
        let projects = Projects()
        let model = ProjectObservationModel(projects: projects)

        projects.emit(.dataChanged)
        #expect(model.revision == 1)

        projects.emit(.selectionChanged(projectID: UUID()))
        #expect(model.revision == 2)
    }

    @Test("会话级事件被忽略，不触发 git 子进程调用")
    func sessionScopedEventsAreIgnored() {
        let projects = Projects()
        let model = ProjectObservationModel(projects: projects)

        projects.emit(.commitSelectionChanged)
        projects.emit(.currentFileChanged)
        projects.emit(.projectsChanged)

        #expect(
            model.revision == 0,
            "session-level selection must not invalidate repository-scoped tiles"
        )
    }

    @Test("仓库级与会话级事件混合时只计入仓库级")
    func mixedEventsCountOnlyRepositoryScoped() {
        let projects = Projects()
        let model = ProjectObservationModel(projects: projects)

        projects.emit(.projectsChanged)
        projects.emit(.dataChanged)
        projects.emit(.currentFileChanged)
        projects.emit(.selectionChanged(projectID: nil))

        #expect(model.revision == 2)
    }
}
