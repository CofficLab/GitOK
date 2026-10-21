import Foundation
import KitGit
import ProviderGit

/// Reusable test doubles for plugin lifecycle suites.
///
/// Several GitOK plugins share the same `onBoot` shape: resolve a status bar,
/// a project store, a Git backend and a scene provider, then register one
/// status bar item. These doubles cover that shared surface so each plugin
/// suite only has to describe its own expectations.
enum CommitFormTestDoubles {

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

        /// 记录提交链路上的调用次数与入参，便于断言提交计划。
        private let calls = NSLock()
        private var _addAllCount = 0
        private var _commitMessages: [String] = []
        private var _pushCount = 0
        private var _synchronizeCount = 0

        var addAllCount: Int {
            calls.lock(); defer { calls.unlock() }
            return _addAllCount
        }

        var commitMessages: [String] {
            calls.lock(); defer { calls.unlock() }
            return _commitMessages
        }

        var pushCount: Int {
            calls.lock(); defer { calls.unlock() }
            return _pushCount
        }

        var synchronizeCount: Int {
            calls.lock(); defer { calls.unlock() }
            return _synchronizeCount
        }

        /// `remoteTrackingStatus` 返回的 upstream 状态。
        var trackingStatus = GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)

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
        func unpushedCount(in repository: URL) -> Int? { nil }
        func hasRemotes(in repository: URL) -> Bool { false }
        func unpulledCount(in repository: URL) -> Int? { nil }
        func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus {
            trackingStatus
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
        func addAll(in repository: URL) throws {
            calls.lock(); defer { calls.unlock() }
            _addAllCount += 1
        }
        func stageFiles(_ filePaths: [String], in repository: URL) throws {}
        func unstageFiles(_ filePaths: [String], in repository: URL) throws {}
        func discardFileChanges(_ filePath: String, in repository: URL) throws {}
        func discardFiles(_ filePaths: [String], in repository: URL) throws {}
        func discardAllChanges(in repository: URL) throws {}
        func commit(message: String, in repository: URL) throws -> String {
            calls.lock(); defer { calls.unlock() }
            _commitMessages.append(message)
            return "commit-hash"
        }
        func push(in repository: URL) throws -> String {
            calls.lock(); defer { calls.unlock() }
            _pushCount += 1
            return "pushed"
        }
        func listRemotes(in repository: URL) -> [GitRemoteSummary] { [] }
        func addRemote(name: String, url: String, in repository: URL) throws {}
        func removeRemote(name: String, in repository: URL) throws {}
        func fetch(in repository: URL) throws {}
        func pull(in repository: URL) throws {}
        func pull(in repository: URL, strategy: GitRemoteOperation.PullStrategy) throws {}
        func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus {
            calls.lock(); defer { calls.unlock() }
            _synchronizeCount += 1
            return GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
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
