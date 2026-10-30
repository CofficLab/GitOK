import Foundation
import KitGit
import ProviderGit
import ProviderStorage
import ProviderToast

/// Test doubles for the clone-repository service suite.
///
/// `CloneRepositoryService` is registered into the kernel as
/// `CloneRepositoryProviding`, so the suite drives it through the public
/// provider contract instead of reaching into private implementation types.

/// A `GitProviding` whose clone step is gated by the test.
///
/// `clone` blocks on a semaphore until the test releases it, which keeps the
/// task observable in its intermediate states (`.cloning` / `.cancelling`)
/// instead of racing against a detached worker.
final class CloneRepositoryTestGit: GitProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var _cloneGate: DispatchSemaphore?
    private var _cloneError: (any Error)?
    private var _remotes: [GitRemoteSummary] = []
    private var _cloneCount = 0
    private var _validateCloneDestinationError: (any Error)?

    var descriptor = GitBackendDescriptor(
        id: "com.coffic.gitok.test.clone.git",
        pluginID: "com.coffic.gitok.test.clone.plugin",
        name: "Test Clone Git",
        priority: 1
    )
    var availableBackends: [GitBackendDescriptor] { [descriptor] }

    /// Gates every subsequent `clone` call until `releaseClone()`.
    var cloneGate: DispatchSemaphore? {
        get { lock.lock(); defer { lock.unlock() }; return _cloneGate }
        set { lock.lock(); defer { lock.unlock() }; _cloneGate = newValue }
    }

    /// Error thrown by `clone` once the gate is released.
    var cloneError: (any Error)? {
        get { lock.lock(); defer { lock.unlock() }; return _cloneError }
        set { lock.lock(); defer { lock.unlock() }; _cloneError = newValue }
    }

    /// Remotes reported by `listRemotes`; drives the external-completion reconciliation.
    var remotes: [GitRemoteSummary] {
        get { lock.lock(); defer { lock.unlock() }; return _remotes }
        set { lock.lock(); defer { lock.unlock() }; _remotes = newValue }
    }

    var cloneCount: Int {
        lock.lock(); defer { lock.unlock() }; return _cloneCount
    }

    var validateCloneDestinationError: (any Error)? {
        get { lock.lock(); defer { lock.unlock() }; return _validateCloneDestinationError }
        set { lock.lock(); defer { lock.unlock() }; _validateCloneDestinationError = newValue }
    }

    /// Releases a blocked clone; a no-op when nothing is waiting.
    func releaseClone() {
        cloneGate?.signal()
        lock.lock(); defer { lock.unlock() }
        _cloneGate = nil
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
    func currentBranch(in repository: URL) -> String? { nil }
    func latestTag(in repository: URL) -> String? { nil }
    func firstCommitDate(in repository: URL) -> Date? { nil }
    func unpushedCount(in repository: URL) -> Int? { nil }
    func hasRemotes(in repository: URL) -> Bool { !remotes.isEmpty }
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

    func validateCloneDestination(_ destination: URL) throws {
        if let error = validateCloneDestinationError { throw error }
    }
    func defaultRepositoryName(from remoteURL: String) -> String? { nil }

    func clone(remoteURL: String, destination: URL) throws -> URL {
        try clone(remoteURL: remoteURL, destination: destination, progress: { _ in })
    }

    func clone(
        remoteURL: String,
        destination: URL,
        progress: @escaping @Sendable (GitCloneProgress) -> Void
    ) throws -> URL {
        try clone(remoteURL: remoteURL, destination: destination, progress: progress, cancellation: nil)
    }

    func clone(
        remoteURL: String,
        destination: URL,
        progress: @escaping @Sendable (GitCloneProgress) -> Void,
        cancellation: GitProcessCancellation?
    ) throws -> URL {
        lock.lock()
        _cloneCount += 1
        let gate = _cloneGate
        let error = _cloneError
        lock.unlock()

        if let gate {
            // Spin on the gate so a cancellation request is noticed promptly.
            let deadline = Date().addingTimeInterval(10)
            while Date() < deadline {
                if cancellation?.isCancelled == true { throw CancellationError() }
                if gate.wait(timeout: .now() + 0.01) == .success { break }
            }
        }

        if cancellation?.isCancelled == true { throw CancellationError() }
        if let error { throw error }

        progress(
            GitCloneProgress(phase: .receivingObjects, fractionCompleted: 0.5, detail: "Receiving objects")
        )
        return destination
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

    func listRemotes(in repository: URL) -> [GitRemoteSummary] { remotes }
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
    func mergeFileDiff(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String { "" }
    func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws {}
    func continueMerge(in repository: URL) throws -> String { "" }
    func abortMerge(in repository: URL) throws -> String { "" }
    func finalizeMergeIfNeeded(in repository: URL) throws -> String? { nil }
}

/// A `StorageProviding` rooted at a temporary directory.
final class CloneRepositoryTestStorage: StorageProviding {
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

/// A `ToastProviding` that records every toast it receives.
@MainActor
final class CloneRepositoryTestToast: ToastProviding {
    private(set) var toasts: [LumiToast] = []
    var currentToast: LumiToast? { toasts.last }

    func show(_ toast: LumiToast) {
        toasts.append(toast)
    }

    func presentError(title: String, message: String, sourceWindowID: String?) {}

    func dismissError() {}
}

/// Error used to drive the clone failure path.
struct CloneRepositoryTestError: LocalizedError {
    let message: String

    init(_ message: String = "clone failed") {
        self.message = message
    }

    var errorDescription: String? { message }
}
