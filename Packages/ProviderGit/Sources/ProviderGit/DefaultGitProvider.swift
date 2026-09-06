import Foundation
import KitGit

/// Git Provider 的稳定路由器。
///
/// 路由器由宿主注册一次；CLI / LibGit2 插件只注册具体后端。路由器本身
/// 不携带 Git 实现，因此切换或禁用后端不会改变业务插件依赖的 Provider 身份。
public final class DefaultGitProvider: @unchecked Sendable, GitProviding {
    private let lock = NSLock()
    private var backends: [String: any GitBackendProviding] = [:]
    private var selectedID: String?

    public init() {}

    public var availableBackends: [GitBackendDescriptor] {
        withLock {
            backends.values.map(\.descriptor).sorted { $0.id < $1.id }
        }
    }

    public var selectedBackendID: String? {
        withLock { selectedID }
    }

    public func registerBackend(_ backend: any GitBackendProviding) throws {
        try withLock {
            let id = backend.descriptor.id
            guard backends[id] == nil else {
                throw GitProviderError.backendAlreadyRegistered(id)
            }
            backends[id] = backend
            if selectedID == nil {
                selectedID = id
            }
        }
    }

    public func unregisterBackend(id: String) {
        withLock {
            backends.removeValue(forKey: id)
            guard selectedID == id else { return }
            selectedID = backends.keys.sorted().first
        }
    }

    public func selectBackend(id: String) throws {
        try withLock {
            guard backends[id] != nil else {
                throw GitProviderError.backendNotFound(id)
            }
            selectedID = id
        }
    }

    private func selectedBackend() throws -> any GitBackendProviding {
        try withLock {
            guard let selectedID, let backend = backends[selectedID] else {
                throw GitProviderError.noBackendAvailable
            }
            return backend
        }
    }

    private func selectedBackendOrNil() -> (any GitBackendProviding)? {
        withLock {
            guard let selectedID else { return nil }
            return backends[selectedID]
        }
    }

    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    // MARK: - GitOperationProviding

    public func loadCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] {
        try selectedBackend().loadCommits(in: repository, limit: limit, offset: offset)
    }

    public func unpushedCommitHashes(in repository: URL) throws -> Set<String> {
        try selectedBackend().unpushedCommitHashes(in: repository)
    }

    public func loadStatus(in repository: URL) throws -> GitWorktreeStatus {
        try selectedBackend().loadStatus(in: repository)
    }

    public func loadEntries(in repository: URL) throws -> [GitStatusEntry] {
        try selectedBackend().loadEntries(in: repository)
    }

    public func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange] {
        try selectedBackend().loadChanges(commit: hash, in: repository)
    }

    public func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String {
        try selectedBackend().loadDiff(commit: hash, filePath: filePath, in: repository)
    }

    public func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String {
        try selectedBackend().loadWorktreeDiff(filePath: filePath, in: repository)
    }

    public func currentBranch(in repository: URL) -> String? {
        selectedBackendOrNil()?.currentBranch(in: repository)
    }

    public func unpushedCount(in repository: URL) -> Int? {
        selectedBackendOrNil()?.unpushedCount(in: repository)
    }

    public func hasRemotes(in repository: URL) -> Bool {
        selectedBackendOrNil()?.hasRemotes(in: repository) ?? false
    }

    public func unpulledCount(in repository: URL) -> Int? {
        selectedBackendOrNil()?.unpulledCount(in: repository)
    }

    public func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus {
        selectedBackendOrNil()?.remoteTrackingStatus(in: repository)
            ?? GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
    }

    public func listBranches(in repository: URL) throws -> [GitBranchSummary] {
        try selectedBackend().listBranches(in: repository)
    }

    public func createBranch(named name: String, in repository: URL) throws {
        try selectedBackend().createBranch(named: name, in: repository)
    }

    public func checkoutBranch(named name: String, in repository: URL) throws {
        try selectedBackend().checkoutBranch(named: name, in: repository)
    }

    public func deleteBranch(named name: String, in repository: URL) throws {
        try selectedBackend().deleteBranch(named: name, in: repository)
    }

    public func renameBranch(from currentName: String, to newName: String, in repository: URL) throws {
        try selectedBackend().renameBranch(from: currentName, to: newName, in: repository)
    }

    public func setUpstream(localBranch: String, upstreamBranch: String, in repository: URL) throws {
        try selectedBackend().setUpstream(localBranch: localBranch, upstreamBranch: upstreamBranch, in: repository)
    }

    public func unsetUpstream(localBranch: String, in repository: URL) throws {
        try selectedBackend().unsetUpstream(localBranch: localBranch, in: repository)
    }

    public func publishBranch(localBranch: String, remote: String, remoteBranch: String?, in repository: URL) throws {
        try selectedBackend().publishBranch(localBranch: localBranch, remote: remote, remoteBranch: remoteBranch, in: repository)
    }

    public func deleteRemoteBranch(named branchName: String, remote: String, in repository: URL) throws {
        try selectedBackend().deleteRemoteBranch(named: branchName, remote: remote, in: repository)
    }

    public func compareBranches(base: String, head: String, in repository: URL) throws -> GitBranchCompare {
        try selectedBackend().compareBranches(base: base, head: head, in: repository)
    }

    public func undoCommit(_ commitHash: String, parentHash: String, in repository: URL) throws -> String {
        try selectedBackend().undoCommit(commitHash, parentHash: parentHash, in: repository)
    }

    public func revertCommit(_ commitHash: String, in repository: URL) throws -> String {
        try selectedBackend().revertCommit(commitHash, in: repository)
    }

    public func softReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try selectedBackend().softReset(to: targetHash, expectedHead: expectedHead, in: repository)
    }

    public func mixedReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try selectedBackend().mixedReset(to: targetHash, expectedHead: expectedHead, in: repository)
    }

    public func hardReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try selectedBackend().hardReset(to: targetHash, expectedHead: expectedHead, in: repository)
    }

    public func squash(to targetHash: String, parentHash: String, expectedHead: String, message: String, in repository: URL) throws -> String {
        try selectedBackend().squash(to: targetHash, parentHash: parentHash, expectedHead: expectedHead, message: message, in: repository)
    }

    public func createLightweightTag(named name: String, at commitHash: String, in repository: URL) throws -> String {
        try selectedBackend().createLightweightTag(named: name, at: commitHash, in: repository)
    }

    public func createAnnotatedTag(named name: String, at commitHash: String, message: String, in repository: URL) throws -> String {
        try selectedBackend().createAnnotatedTag(named: name, at: commitHash, message: message, in: repository)
    }

    public func deleteLocalTag(named name: String, in repository: URL) throws -> String {
        try selectedBackend().deleteLocalTag(named: name, in: repository)
    }

    public func pushTag(named name: String, remote: String, in repository: URL) throws -> String {
        try selectedBackend().pushTag(named: name, remote: remote, in: repository)
    }

    public func deleteRemoteTag(named name: String, remote: String, in repository: URL) throws -> String {
        try selectedBackend().deleteRemoteTag(named: name, remote: remote, in: repository)
    }

    public func listStashes(in repository: URL) -> [GitStashEntry] {
        selectedBackendOrNil()?.listStashes(in: repository) ?? []
    }

    public func hasChangesToStash(in repository: URL) -> Bool {
        selectedBackendOrNil()?.hasChangesToStash(in: repository) ?? false
    }

    public func saveStash(message: String?, in repository: URL) throws {
        try selectedBackend().saveStash(message: message, in: repository)
    }

    public func applyStash(_ entry: GitStashEntry, in repository: URL) throws {
        try selectedBackend().applyStash(entry, in: repository)
    }

    public func popStash(_ entry: GitStashEntry, in repository: URL) throws {
        try selectedBackend().popStash(entry, in: repository)
    }

    public func dropStash(_ entry: GitStashEntry, in repository: URL) throws {
        try selectedBackend().dropStash(entry, in: repository)
    }

    public func cherryPickStatus(in repository: URL) -> GitCherryPickStatus {
        selectedBackendOrNil()?.cherryPickStatus(in: repository) ?? .inactive
    }

    public func cherryPick(commits: [String], onto branch: String?, in repository: URL) throws -> String {
        try selectedBackend().cherryPick(commits: commits, onto: branch, in: repository)
    }

    public func continueCherryPick(in repository: URL) throws -> String {
        try selectedBackend().continueCherryPick(in: repository)
    }

    public func abortCherryPick(in repository: URL) throws -> String {
        try selectedBackend().abortCherryPick(in: repository)
    }

    public func listSubmodules(in repository: URL) -> [GitSubmoduleSummary] {
        selectedBackendOrNil()?.listSubmodules(in: repository) ?? []
    }

    public func updateSubmodules(in repository: URL) throws {
        try selectedBackend().updateSubmodules(in: repository)
    }

    public func validateCloneDestination(_ destination: URL) throws {
        try selectedBackend().validateCloneDestination(destination)
    }

    public func defaultRepositoryName(from remoteURL: String) -> String? {
        selectedBackendOrNil()?.defaultRepositoryName(from: remoteURL)
    }

    public func clone(remoteURL: String, destination: URL) throws -> URL {
        try selectedBackend().clone(remoteURL: remoteURL, destination: destination)
    }

    public func hasStagedChanges(in repository: URL) throws -> Bool {
        try selectedBackend().hasStagedChanges(in: repository)
    }

    public func addAll(in repository: URL) throws {
        try selectedBackend().addAll(in: repository)
    }

    public func stageFiles(_ filePaths: [String], in repository: URL) throws {
        try selectedBackend().stageFiles(filePaths, in: repository)
    }

    public func unstageFiles(_ filePaths: [String], in repository: URL) throws {
        try selectedBackend().unstageFiles(filePaths, in: repository)
    }

    public func discardFileChanges(_ filePath: String, in repository: URL) throws {
        try selectedBackend().discardFileChanges(filePath, in: repository)
    }

    public func discardFiles(_ filePaths: [String], in repository: URL) throws {
        try selectedBackend().discardFiles(filePaths, in: repository)
    }

    public func commit(message: String, in repository: URL) throws -> String {
        try selectedBackend().commit(message: message, in: repository)
    }

    public func push(in repository: URL) throws -> String {
        try selectedBackend().push(in: repository)
    }

    public func listRemotes(in repository: URL) -> [GitRemoteSummary] {
        selectedBackendOrNil()?.listRemotes(in: repository) ?? []
    }

    public func addRemote(name: String, url: String, in repository: URL) throws {
        try selectedBackend().addRemote(name: name, url: url, in: repository)
    }

    public func removeRemote(name: String, in repository: URL) throws {
        try selectedBackend().removeRemote(name: name, in: repository)
    }

    public func fetch(in repository: URL) throws {
        try selectedBackend().fetch(in: repository)
    }

    public func pull(in repository: URL) throws {
        try selectedBackend().pull(in: repository)
    }

    public func pull(in repository: URL, strategy: GitRemoteOperation.PullStrategy) throws {
        try selectedBackend().pull(in: repository, strategy: strategy)
    }

    public func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus {
        try selectedBackend().synchronize(in: repository)
    }

    public func webLink(for url: String) -> URL? {
        selectedBackendOrNil()?.webLink(for: url)
    }

    public func isMerging(in repository: URL) -> Bool {
        selectedBackendOrNil()?.isMerging(in: repository) ?? false
    }

    public func hasConflictOperation(in repository: URL) -> Bool {
        selectedBackendOrNil()?.hasConflictOperation(in: repository) ?? false
    }

    public func conflictFiles(in repository: URL) -> [String] {
        selectedBackendOrNil()?.conflictFiles(in: repository) ?? []
    }

    public func mergeBranches(repository: URL, sourceBranch: String, targetBranch: String) throws -> String {
        try selectedBackend().mergeBranches(
            repository: repository,
            sourceBranch: sourceBranch,
            targetBranch: targetBranch
        )
    }

    public func mergeFileContent(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String {
        try selectedBackend().mergeFileContent(path: path, version: version, in: repository)
    }

    public func mergeFileDiff(path: String, in repository: URL) throws -> String {
        try selectedBackend().mergeFileDiff(path: path, in: repository)
    }

    public func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws {
        try selectedBackend().checkoutMergeFileVersion(path: path, version: version, in: repository)
    }

    public func continueMerge(in repository: URL) throws -> String {
        try selectedBackend().continueMerge(in: repository)
    }

    public func abortMerge(in repository: URL) throws -> String {
        try selectedBackend().abortMerge(in: repository)
    }

    public func finalizeMergeIfNeeded(in repository: URL) throws -> String? {
        try selectedBackend().finalizeMergeIfNeeded(in: repository)
    }
}
