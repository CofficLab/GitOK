import Foundation
import KitGit
import ProviderGit

/// 一个只关心「工作区内容归属」广播的 `GitProviding` 测试替身。
///
/// 生产链路里，归属广播由 `DefaultGitProvider` 持有：每次工作区扫描后，
/// 它按**仓库**发布一次结论（`pending` / `changes` / `clean`），并把这个
/// 结论推给所有订阅者。订阅者必须自己判断这条结论说的是不是自己当前的
/// 项目——预热插件会在后台扫描侧边栏里的**每一个**项目。
///
/// 这个替身复用生产代码里同一个 `WorktreeContentOwnership` 存储，因此
/// 「同一仓库结论不变时不重复通知」「跨仓库广播会推给所有订阅者」这两条
/// 语义与线上一致。
final class WorktreeOwnerGitDouble: GitProviding, @unchecked Sendable {
    let descriptor = GitBackendDescriptor(
        id: "com.coffic.gitok.test.git.worktree-owner",
        pluginID: "com.coffic.gitok.test.plugin",
        name: "Worktree Owner Git",
        priority: 1
    )

    private let ownership = WorktreeContentOwnership()
    private let lock = NSLock()
    private var storage: [String: any GitBackendProviding] = [:]

    var availableBackends: [GitBackendDescriptor] { [descriptor] }

    // MARK: - Worktree ownership (the part under test)

    func worktreeContentOwner(for repository: URL) -> WorktreeContentOwner {
        ownership.owner(for: repository)
    }

    func addWorktreeContentOwnerObserver(
        _ callback: @escaping @MainActor @Sendable (URL, WorktreeContentOwner) -> Void
    ) -> any WorktreeContentOwnerObserverHandle {
        ownership.addObserver(callback)
    }

    /// 测试辅助：模拟「某个仓库被扫描完毕并发布了归属结论」。
    ///
    /// 生产环境里这一步发生在 `DefaultGitProvider.loadWorktreeSnapshot` 末尾，
    /// 包括预热插件扫描侧边栏里其它项目时。
    func simulateScan(publishing owner: WorktreeContentOwner, for repository: URL) {
        ownership.publish(owner: owner, for: repository)
    }

    // MARK: - Backend registry

    func registerBackend(_ backend: any GitBackendProviding) throws {
        lock.lock(); defer { lock.unlock() }
        storage[backend.descriptor.id] = backend
    }

    func unregisterBackend(id: String) {
        lock.lock(); defer { lock.unlock() }
        storage[id] = nil
    }

    // MARK: - Neutral Git operations

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
    func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange] { [] }
    func countCommitChanges(commit hash: String, in repository: URL) throws -> Int { 0 }
    func loadCommitChangesPage(
        commit hash: String,
        limit: Int,
        offset: Int,
        in repository: URL
    ) throws -> GitFileChangePage {
        GitFileChangePage(offset: offset, changes: [], hasMore: false)
    }
    func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String { "" }
    func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String { "" }
    func loadBlobData(commit: String, filePath: String, in repository: URL) throws -> Data { Data() }
    func loadWorktreeFileData(filePath: String, in repository: URL) throws -> Data { Data() }
    func currentBranch(in repository: URL) -> String? { nil }
    func latestTag(in repository: URL) -> String? { nil }
    func firstCommitDate(in repository: URL) -> Date? { nil }
    func unpushedCount(in repository: URL) -> Int? { nil }
    func hasRemotes(in repository: URL) -> Bool { false }
    func unpulledCount(in repository: URL) -> Int? { nil }
    func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus {
        GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
    }
    func listBranches(in repository: URL) throws -> [GitBranchSummary] { [] }
    func createBranch(named name: String, in repository: URL) throws {}
    func checkoutBranch(named branchName: String, in repository: URL) throws {}
    func checkoutRemoteBranch(named remoteBranch: String, as localBranch: String?, in repository: URL) throws {}
    func deleteBranch(named branchName: String, in repository: URL) throws {}
    func renameBranch(from currentName: String, to newName: String, in repository: URL) throws {}
    func setUpstream(localBranch: String, upstreamBranch: String, in repository: URL) throws {}
    func unsetUpstream(localBranch: String, in repository: URL) throws {}
    func publishBranch(localBranch: String, remote: String, remoteBranch: String?, in repository: URL) throws {}
    func deleteRemoteBranch(named branchName: String, remote: String, in repository: URL) throws {}
    func compareBranches(base: String, head: String, in repository: URL) throws -> GitBranchCompare {
        GitBranchCompare(base: base, head: head, ahead: 0, behind: 0, commits: [], files: [])
    }
    func undoCommit(_ commitHash: String, parentHash: String, in repository: URL) throws -> String { "" }
    func revertCommit(_ commitHash: String, in repository: URL) throws -> String { "" }
    func softReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func mixedReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func hardReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func squash(
        to targetHash: String,
        parentHash: String,
        expectedHead: String,
        message: String,
        in repository: URL
    ) throws -> String { "" }
    func createLightweightTag(named name: String, at commitHash: String, in repository: URL) throws -> String { "" }
    func createAnnotatedTag(
        named name: String,
        at commitHash: String,
        message: String,
        in repository: URL
    ) throws -> String { "" }
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
