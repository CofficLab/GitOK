import Foundation
import KitGit
import ProviderGit

/// `GitProviding` 的可控替身（仅实现分支状态插件真正调用的接口）。
///
/// `GitProviding` 协议面很大，这里照抄 GitOK 其余插件测试里通用的替身实现，
/// 只把 `currentBranch` 换成可配置值。
// MARK: - GitProviding mock

/// 只实现 observer 会真正调用的读取接口的 `GitProviding` 替身。
///
/// 快照读取在 detached task 里并发访问可变状态，因此用锁保护。
/// 其余成员为桩实现，本测试不涉及。
final class BranchStatusGitProviding: @unchecked Sendable, GitProviding {
    enum TestError: Error { case failed }

    private let lock = NSLock()

    private var _conflictFiles: [String] = []
    private var _isMerging = false
    private var _cherryPickStatus: GitCherryPickStatus = .inactive
    private var _conflictFileReadCount = 0
    /// 为 true 时快照读取会阻塞，直到 `releaseConflictFiles()`，用于稳定复现竞态。
    private var _blocksConflictFileRead = false
    private var _isConflictFileReadBlocked = false

    var conflictFilesStub: [String] {
        get { lock.lock(); defer { lock.unlock() }; return _conflictFiles }
        set { lock.lock(); defer { lock.unlock() }; _conflictFiles = newValue }
    }

    var isMergingStub: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _isMerging }
        set { lock.lock(); defer { lock.unlock() }; _isMerging = newValue }
    }

    var cherryPickStatusStub: GitCherryPickStatus {
        get { lock.lock(); defer { lock.unlock() }; return _cherryPickStatus }
        set { lock.lock(); defer { lock.unlock() }; _cherryPickStatus = newValue }
    }

    var conflictFileReadCount: Int {
        lock.lock(); defer { lock.unlock() }; return _conflictFileReadCount
    }

    var blocksConflictFileRead: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _blocksConflictFileRead }
        set { lock.lock(); defer { lock.unlock() }; _blocksConflictFileRead = newValue }
    }

    var isConflictFileReadBlocked: Bool {
        lock.lock(); defer { lock.unlock() }; return _isConflictFileReadBlocked
    }

    /// 解除 `blocksConflictFileRead` 造成的阻塞。
    func releaseConflictFiles() {
        lock.lock(); defer { lock.unlock() }
        _blocksConflictFileRead = false
    }

    // MARK: - 被 observer 调用的接口

    func conflictFiles(in repository: URL) -> [String] {
        lock.lock()
        _conflictFileReadCount += 1
        let files = _conflictFiles
        let blocked = _blocksConflictFileRead
        _isConflictFileReadBlocked = blocked
        lock.unlock()

        if blocked {
            // 用轮询而非条件变量：只服务测试，避免引入额外同步原语。
            while self.blocksConflictFileRead {
                Thread.sleep(forTimeInterval: 0.002)
            }
            self.lock.lock(); self._isConflictFileReadBlocked = false; self.lock.unlock()
        }
        return files
    }

    func isMerging(in repository: URL) -> Bool { isMergingStub }
    func cherryPickStatus(in repository: URL) -> GitCherryPickStatus { cherryPickStatusStub }

    // MARK: - 桩实现（本测试不调用）

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
    /// 可配置的当前分支返回值。
    var currentBranchStub: String?

    func currentBranch(in repository: URL) -> String? { currentBranchStub }
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
    func undoCommit(_ commitHash: String, parentHash: String, in repository: URL) throws -> String { "" }
    func revertCommit(_ commitHash: String, in repository: URL) throws -> String { "" }
    func softReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func mixedReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func hardReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func squash(to targetHash: String, parentHash: String, expectedHead: String, message: String, in repository: URL) throws -> String { "" }
    func createLightweightTag(named name: String, at commitHash: String, in repository: URL) throws -> String { "" }
    func createAnnotatedTag(named name: String, at commitHash: String, message: String, in repository: URL) throws -> String { "" }
    func deleteLocalTag(named name: String, in repository: URL) throws -> String { "" }
    func pushTag(named name: String, remote: String, in repository: URL) throws -> String { "" }
    func deleteRemoteTag(named name: String, remote: String, in repository: URL) throws -> String { "" }
    func listStashes(in repository: URL) -> [GitStashEntry] { [] }
    func hasChangesToStash(in repository: URL) -> Bool { false }
    func saveStash(message: String?, in repository: URL) throws {}
    func applyStash(_ entry: GitStashEntry, in repository: URL) throws {}
    func popStash(_ entry: GitStashEntry, in repository: URL) throws {}
    func dropStash(_ entry: GitStashEntry, in repository: URL) throws {}
    func cherryPick(commits: [String], onto branch: String?, in repository: URL) throws -> String { "" }
    func continueCherryPick(in repository: URL) throws -> String { "" }
    func abortCherryPick(in repository: URL) throws -> String { "" }
    func listSubmodules(in repository: URL) -> [GitSubmoduleSummary] { [] }
    func updateSubmodules(in repository: URL) throws {}
    func validateCloneDestination(_ destination: URL) throws {}
    func defaultRepositoryName(from remoteURL: String) -> String? { nil }
    func clone(remoteURL: String, destination: URL) throws -> URL {
        throw TestError.failed
    }
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
    func hasConflictOperation(in repository: URL) -> Bool { false }
    func mergeBranches(repository: URL, sourceBranch: String, targetBranch: String) throws -> String { "" }
    func mergeFileContent(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String { "" }
    func mergeFileDiff(path: String, in repository: URL) throws -> String { "" }
    func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws {}
    func continueMerge(in repository: URL) throws -> String { "" }
    func abortMerge(in repository: URL) throws -> String { "" }
    func finalizeMergeIfNeeded(in repository: URL) throws -> String? { nil }

    // MARK: - GitBackendRegistryProviding

    var availableBackends: [GitBackendDescriptor] { [] }
    func registerBackend(_ backend: any GitBackendProviding) throws {}
    func unregisterBackend(id: String) {}
}
