import Foundation
import KernelCore
import KitGit
import ProviderGit
import ProviderProjects

/// Reusable test doubles for plugin lifecycle suites.
///
/// `ProjectProviding` 与 `GitProviding` 的空实现：生命周期套件只需要这些
/// 协议类型能被内核解析出来，好让 `onBoot` 越过守卫链。
enum WorktreePreheatDoubles {

    /// Empty `ProjectProviding`; lifecycle suites only assert wiring.
    @MainActor
    final class Projects: ProjectProviding {
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
        func moveProject(id: UUID, beforeID: UUID?) {}
        func selectCommit(_ commit: GitCommit) { currentCommit = commit }
        func selectFile(_ file: String?) { currentFile = file }
        func clearCommitSelection() { currentCommit = nil; currentFile = nil }
        func setCurrentProject(id: UUID?) {}
        func refresh() {}
        func notifyDataChanged() {}
        func persist() {}
        func addObserver(
            _ callback: @escaping (ProjectProvidingEvent) -> Void
        ) -> any ProjectProvidingObserverHandle {
            ProjectHandle()
        }
    }

    @MainActor
    final class ProjectHandle: ProjectProvidingObserverHandle {
        func cancel() {}
    }

    /// A `GitProviding` whose every read returns a neutral value.
    ///
    /// Lifecycle suites never exercise Git itself; they only need the router
    /// type to resolve so `onBoot` can continue past its guards.
    final class Git: GitProviding, @unchecked Sendable {
        let descriptor = GitBackendDescriptor(
            id: "com.coffic.gitok.test.git",
            pluginID: "com.coffic.gitok.test.plugin",
            name: "Test Git",
            priority: 1
        )
        private let lock = NSLock()
        private var storage: [String: any GitBackendProviding] = [:]
        var availableBackends: [GitBackendDescriptor] { [descriptor] }

        /// 记录快照加载与失效次数，便于断言插件把 Git 回调接到了预热器上。
        private let counters = NSLock()
        private var _loadWorktreeSnapshotCount = 0
        private var _invalidateWorktreeSnapshotCount = 0

        var loadWorktreeSnapshotCount: Int {
            counters.lock(); defer { counters.unlock() }
            return _loadWorktreeSnapshotCount
        }

        var invalidateWorktreeSnapshotCount: Int {
            counters.lock(); defer { counters.unlock() }
            return _invalidateWorktreeSnapshotCount
        }

        func registerBackend(_ backend: any GitBackendProviding) throws {
            lock.lock(); defer { lock.unlock() }
            storage[backend.descriptor.id] = backend
        }

        func unregisterBackend(id: String) {
            lock.lock(); defer { lock.unlock() }
            storage[id] = nil
        }

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
            counters.lock(); defer { counters.unlock() }
            _loadWorktreeSnapshotCount += 1
            return GitWorktreeSnapshot(entries: [], branch: nil)
        }
        func loadWorktreeSnapshot(
            in repository: URL,
            cancellation: GitProcessCancellation?
        ) throws -> GitWorktreeSnapshot {
            counters.lock(); defer { counters.unlock() }
            _loadWorktreeSnapshotCount += 1
            return GitWorktreeSnapshot(entries: [], branch: nil)
        }
        func cachedWorktreeSnapshot(in repository: URL) -> GitWorktreeSnapshot? { nil }
        func invalidateWorktreeSnapshot(in repository: URL) {
            counters.lock(); defer { counters.unlock() }
            _invalidateWorktreeSnapshotCount += 1
        }
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
        func unpushedCount(in repository: URL) -> Int? { nil }
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
}
