import Foundation
import KitGit
import ProviderCommitForm
import ProviderGit
import ProviderProjects
import ProviderStorage

/// Test doubles for the auto-push plugin suite.
///
/// The plugin only needs a Git backend that can report the current branch and
/// record pushes, a project store, a commit form that can emit `.committed`,
/// and a storage root. Everything else is a neutral stub.

/// A `GitProviding` that records push calls and reports a fixed branch.
final class AutoPushTestGit: GitProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var _pushCount = 0
    private var _pushedRepositories: [String] = []
    private var _branch: String? = "main"

    var descriptor = GitBackendDescriptor(
        id: "com.coffic.gitok.test.autopush.git",
        pluginID: "com.coffic.gitok.test.autopush.plugin",
        name: "Test Auto Push Git",
        priority: 1
    )
    var availableBackends: [GitBackendDescriptor] { [descriptor] }

    var pushCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _pushCount
    }

    var pushedRepositories: [String] {
        lock.lock(); defer { lock.unlock() }
        return _pushedRepositories
    }

    /// 分支名；设为 nil 时表示仓库没有当前分支（自动推送应当跳过）。
    var currentBranchName: String? {
        get { lock.lock(); defer { lock.unlock() }; return _branch }
        set { lock.lock(); defer { lock.unlock() }; _branch = newValue }
    }

    func registerBackend(_ backend: any GitBackendProviding) throws {}
    func unregisterBackend(id: String) {}

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
    func currentBranch(in repository: URL) -> String? { currentBranchName }
    func latestTag(in repository: URL) -> String? { nil }
    func firstCommitDate(in repository: URL) -> Date? { nil }
    func unpushedCount(in repository: URL) -> Int? { nil }
    func hasRemotes(in repository: URL) -> Bool { true }
    func unpulledCount(in repository: URL) -> Int? { nil }
    func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus {
        GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: true)
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
    func commit(message: String, in repository: URL) throws -> String { "commit-hash" }

    func push(in repository: URL) throws -> String {
        lock.lock(); defer { lock.unlock() }
        _pushCount += 1
        _pushedRepositories.append(repository.path)
        return "pushed"
    }

    func listRemotes(in repository: URL) -> [GitRemoteSummary] { [] }
    func addRemote(name: String, url: String, in repository: URL) throws {}
    func removeRemote(name: String, in repository: URL) throws {}
    func fetch(in repository: URL) throws {}
    func pull(in repository: URL) throws {}
    func pull(in repository: URL, strategy: GitRemoteOperation.PullStrategy) throws {}
    func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus {
        GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: true)
    }
    func webLink(for url: String) -> URL? { nil }
    func isMerging(in repository: URL) -> Bool { false }
    func hasConflictOperation(in repository: URL) -> Bool { false }
    func conflictFiles(in repository: URL) -> [String] { [] }
    func mergeBranches(repository: URL, sourceBranch: String, targetBranch: String) throws -> String { "" }
    func mergeFileContent(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String { "" }
    func mergeFileDiff(path: String, in repository: URL) throws -> String { "" }
    func mergeFileDiff(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String { "" }
    func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws {}
    func continueMerge(in repository: URL) throws -> String { "" }
    func abortMerge(in repository: URL) throws -> String { "" }
    func finalizeMergeIfNeeded(in repository: URL) throws -> String? { nil }
}

/// `ProjectProviding` 的最小替身：只关心「当前项目」与观察者注册。
@MainActor
final class AutoPushTestProjects: ProjectProviding {
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
        AutoPushTestProjectHandle()
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
final class AutoPushTestProjectHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}

/// `CommitFormProviding` 的最小替身：可手动派发 `.committed` 事件。
@MainActor
final class AutoPushTestCommitForm: CommitFormProviding {
    var subject = ""
    var category: CommitCategory = .Chore
    var style: CommitStyle = .emoji
    var coAuthors: [ProviderCommitForm.CoAuthor] = []
    var isSubmitting = false
    var lastErrorMessage: String?

    private var observers: [UUID: (CommitFormEvent) -> Void] = [:]

    func addObserver(
        _ callback: @escaping (CommitFormEvent) -> Void
    ) -> any CommitFormObserverHandle {
        let id = UUID()
        observers[id] = callback
        return AutoPushTestCommitFormHandle { [weak self] in self?.observers.removeValue(forKey: id) }
    }

    /// 派发一次「提交成功」事件。
    func emitCommitted() {
        observers.values.forEach { $0(.committed) }
    }

    func setSubject(_ subject: String) { self.subject = subject }
    func setCategory(_ category: CommitCategory) { self.category = category }
    func setStyle(_ style: CommitStyle) { self.style = style }
    func style(for projectURL: URL) -> CommitStyle { style }
    func setStyle(_ style: CommitStyle, for projectURL: URL) { self.style = style }
    func loadStyle(for projectURL: URL?) {}
    func setCoAuthors(_ coAuthors: [ProviderCommitForm.CoAuthor]) { self.coAuthors = coAuthors }
    func submit(commitOnly: Bool, in repository: URL) async throws {}
}

@MainActor
final class AutoPushTestCommitFormHandle: CommitFormObserverHandle {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() { onCancel() }
}

/// 只实现 `pluginDataDirectory` 的最小存储 Provider。
final class AutoPushTestStorage: StorageProviding {
    let dataRootDirectory: URL

    init(dataRootDirectory: URL) {
        self.dataRootDirectory = dataRootDirectory
    }

    func pluginDataDirectory(for pluginID: String) -> URL {
        dataRootDirectory.appendingPathComponent(pluginID, isDirectory: true)
    }

    func coreDataDirectory() -> URL {
        dataRootDirectory.appendingPathComponent("CoreData", isDirectory: true)
    }
}
