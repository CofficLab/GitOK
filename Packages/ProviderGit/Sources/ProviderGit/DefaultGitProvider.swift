import Foundation
import KitGit

/// Git Provider 的稳定路由器。
///
/// 路由器由宿主注册一次；每个 Git 实现插件只注册具体后端。业务插件永远
/// 不需要知道当前由哪个实现执行 Git 操作。后端按优先级排列，能力不支持
/// 时自动尝试下一个后端。
public final class DefaultGitProvider: @unchecked Sendable, GitProviding {
    private let lock = NSLock()
    private var backends: [String: any GitBackendProviding] = [:]

    public init() {}

    public var availableBackends: [GitBackendDescriptor] {
        withLock {
            backends.values
                .filter(\.isAvailable)
                .map(\.descriptor)
                .sorted(by: Self.backendOrder)
        }
    }

    public func registerBackend(_ backend: any GitBackendProviding) throws {
        try withLock {
            let id = backend.descriptor.id
            guard backends[id] == nil else {
                throw GitProviderError.backendAlreadyRegistered(id)
            }
            backends[id] = backend
        }
    }

    public func unregisterBackend(id: String) {
        withLock {
            backends.removeValue(forKey: id)
            return ()
        }
    }

    private func orderedBackends() -> [any GitBackendProviding] {
        withLock {
            backends.values
                .filter(\.isAvailable)
                .sorted { Self.backendOrder($0.descriptor, $1.descriptor) }
        }
    }

    private func primaryBackendOrNil() -> (any GitBackendProviding)? {
        orderedBackends().first
    }

    private func execute<T>(
        _ operation: String,
        _ body: (any GitBackendProviding) throws -> T
    ) throws -> T {
        let candidates = orderedBackends()
        guard !candidates.isEmpty else {
            throw GitProviderError.noBackendAvailable
        }

        var failures: [GitProviderError.GitBackendFailure] = []
        for backend in candidates {
            do {
                return try body(backend)
            } catch GitProviderError.backendOperationUnsupported(let message) {
                failures.append(
                    .init(
                        backendID: backend.descriptor.id,
                        backendName: backend.descriptor.name,
                        message: message
                    )
                )
            } catch {
                // 对写操作和认证/仓库错误不做盲目重试，避免操作已经发生
                // 但响应丢失时由另一个后端再次执行。
                throw error
            }
        }

        throw GitProviderError.allBackendsFailed(operation: operation, failures: failures)
    }

    private static func backendOrder(
        _ lhs: GitBackendDescriptor,
        _ rhs: GitBackendDescriptor
    ) -> Bool {
        if lhs.priority != rhs.priority {
            return lhs.priority > rhs.priority
        }
        return lhs.id < rhs.id
    }

    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    // MARK: - GitOperationProviding

    public func loadCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] {
        try execute("loadCommits") { try $0.loadCommits(in: repository, limit: limit, offset: offset) }
    }

    public func countCommits(in repository: URL) throws -> Int {
        try execute("countCommits") { try $0.countCommits(in: repository) }
    }

    public func unpushedCommitHashes(in repository: URL) throws -> Set<String> {
        try execute("unpushedCommitHashes") { try $0.unpushedCommitHashes(in: repository) }
    }

    public func loadStatus(in repository: URL) throws -> GitWorktreeStatus {
        try execute("loadStatus") { try $0.loadStatus(in: repository) }
    }

    public func loadEntries(in repository: URL) throws -> [GitStatusEntry] {
        try execute("loadEntries") { try $0.loadEntries(in: repository) }
    }

    public func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange] {
        try execute("loadChanges") { try $0.loadChanges(commit: hash, in: repository) }
    }

    public func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String {
        try execute("loadDiff") { try $0.loadDiff(commit: hash, filePath: filePath, in: repository) }
    }

    public func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String {
        try execute("loadWorktreeDiff") { try $0.loadWorktreeDiff(filePath: filePath, in: repository) }
    }

    public func currentBranch(in repository: URL) -> String? {
        primaryBackendOrNil()?.currentBranch(in: repository)
    }

    public func latestTag(in repository: URL) -> String? {
        primaryBackendOrNil()?.latestTag(in: repository)
    }

    public func firstCommitDate(in repository: URL) -> Date? {
        primaryBackendOrNil()?.firstCommitDate(in: repository)
    }

    public func unpushedCount(in repository: URL) -> Int? {
        primaryBackendOrNil()?.unpushedCount(in: repository)
    }

    public func hasRemotes(in repository: URL) -> Bool {
        primaryBackendOrNil()?.hasRemotes(in: repository) ?? false
    }

    public func unpulledCount(in repository: URL) -> Int? {
        primaryBackendOrNil()?.unpulledCount(in: repository)
    }

    public func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus {
        primaryBackendOrNil()?.remoteTrackingStatus(in: repository)
            ?? GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
    }

    public func listBranches(in repository: URL) throws -> [GitBranchSummary] {
        try execute("listBranches") { try $0.listBranches(in: repository) }
    }

    public func createBranch(named name: String, in repository: URL) throws {
        try execute("createBranch") { try $0.createBranch(named: name, in: repository) }
    }

    public func checkoutBranch(named name: String, in repository: URL) throws {
        try execute("checkoutBranch") { try $0.checkoutBranch(named: name, in: repository) }
    }

    public func deleteBranch(named name: String, in repository: URL) throws {
        try execute("deleteBranch") { try $0.deleteBranch(named: name, in: repository) }
    }

    public func renameBranch(from currentName: String, to newName: String, in repository: URL) throws {
        try execute("renameBranch") { try $0.renameBranch(from: currentName, to: newName, in: repository) }
    }

    public func setUpstream(localBranch: String, upstreamBranch: String, in repository: URL) throws {
        try execute("setUpstream") { try $0.setUpstream(localBranch: localBranch, upstreamBranch: upstreamBranch, in: repository) }
    }

    public func unsetUpstream(localBranch: String, in repository: URL) throws {
        try execute("unsetUpstream") { try $0.unsetUpstream(localBranch: localBranch, in: repository) }
    }

    public func publishBranch(localBranch: String, remote: String, remoteBranch: String?, in repository: URL) throws {
        try execute("publishBranch") { try $0.publishBranch(localBranch: localBranch, remote: remote, remoteBranch: remoteBranch, in: repository) }
    }

    public func deleteRemoteBranch(named branchName: String, remote: String, in repository: URL) throws {
        try execute("deleteRemoteBranch") { try $0.deleteRemoteBranch(named: branchName, remote: remote, in: repository) }
    }

    public func compareBranches(base: String, head: String, in repository: URL) throws -> GitBranchCompare {
        try execute("compareBranches") { try $0.compareBranches(base: base, head: head, in: repository) }
    }

    public func undoCommit(_ commitHash: String, parentHash: String, in repository: URL) throws -> String {
        try execute("undoCommit") { try $0.undoCommit(commitHash, parentHash: parentHash, in: repository) }
    }

    public func revertCommit(_ commitHash: String, in repository: URL) throws -> String {
        try execute("revertCommit") { try $0.revertCommit(commitHash, in: repository) }
    }

    public func softReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try execute("softReset") { try $0.softReset(to: targetHash, expectedHead: expectedHead, in: repository) }
    }

    public func mixedReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try execute("mixedReset") { try $0.mixedReset(to: targetHash, expectedHead: expectedHead, in: repository) }
    }

    public func hardReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try execute("hardReset") { try $0.hardReset(to: targetHash, expectedHead: expectedHead, in: repository) }
    }

    public func squash(to targetHash: String, parentHash: String, expectedHead: String, message: String, in repository: URL) throws -> String {
        try execute("squash") { try $0.squash(to: targetHash, parentHash: parentHash, expectedHead: expectedHead, message: message, in: repository) }
    }

    public func createLightweightTag(named name: String, at commitHash: String, in repository: URL) throws -> String {
        try execute("createLightweightTag") { try $0.createLightweightTag(named: name, at: commitHash, in: repository) }
    }

    public func createAnnotatedTag(named name: String, at commitHash: String, message: String, in repository: URL) throws -> String {
        try execute("createAnnotatedTag") { try $0.createAnnotatedTag(named: name, at: commitHash, message: message, in: repository) }
    }

    public func deleteLocalTag(named name: String, in repository: URL) throws -> String {
        try execute("deleteLocalTag") { try $0.deleteLocalTag(named: name, in: repository) }
    }

    public func pushTag(named name: String, remote: String, in repository: URL) throws -> String {
        try execute("pushTag") { try $0.pushTag(named: name, remote: remote, in: repository) }
    }

    public func deleteRemoteTag(named name: String, remote: String, in repository: URL) throws -> String {
        try execute("deleteRemoteTag") { try $0.deleteRemoteTag(named: name, remote: remote, in: repository) }
    }

    public func listStashes(in repository: URL) -> [GitStashEntry] {
        primaryBackendOrNil()?.listStashes(in: repository) ?? []
    }

    public func hasChangesToStash(in repository: URL) -> Bool {
        primaryBackendOrNil()?.hasChangesToStash(in: repository) ?? false
    }

    public func saveStash(message: String?, in repository: URL) throws {
        try execute("saveStash") { try $0.saveStash(message: message, in: repository) }
    }

    public func applyStash(_ entry: GitStashEntry, in repository: URL) throws {
        try execute("applyStash") { try $0.applyStash(entry, in: repository) }
    }

    public func popStash(_ entry: GitStashEntry, in repository: URL) throws {
        try execute("popStash") { try $0.popStash(entry, in: repository) }
    }

    public func dropStash(_ entry: GitStashEntry, in repository: URL) throws {
        try execute("dropStash") { try $0.dropStash(entry, in: repository) }
    }

    public func cherryPickStatus(in repository: URL) -> GitCherryPickStatus {
        primaryBackendOrNil()?.cherryPickStatus(in: repository) ?? .inactive
    }

    public func cherryPick(commits: [String], onto branch: String?, in repository: URL) throws -> String {
        try execute("cherryPick") { try $0.cherryPick(commits: commits, onto: branch, in: repository) }
    }

    public func continueCherryPick(in repository: URL) throws -> String {
        try execute("continueCherryPick") { try $0.continueCherryPick(in: repository) }
    }

    public func abortCherryPick(in repository: URL) throws -> String {
        try execute("abortCherryPick") { try $0.abortCherryPick(in: repository) }
    }

    public func listSubmodules(in repository: URL) -> [GitSubmoduleSummary] {
        primaryBackendOrNil()?.listSubmodules(in: repository) ?? []
    }

    public func updateSubmodules(in repository: URL) throws {
        try execute("updateSubmodules") { try $0.updateSubmodules(in: repository) }
    }

    public func validateCloneDestination(_ destination: URL) throws {
        try execute("validateCloneDestination") { try $0.validateCloneDestination(destination) }
    }

    public func defaultRepositoryName(from remoteURL: String) -> String? {
        primaryBackendOrNil()?.defaultRepositoryName(from: remoteURL)
    }

    public func clone(remoteURL: String, destination: URL) throws -> URL {
        try execute("clone") { try $0.clone(remoteURL: remoteURL, destination: destination) }
    }

    public func hasStagedChanges(in repository: URL) throws -> Bool {
        try execute("hasStagedChanges") { try $0.hasStagedChanges(in: repository) }
    }

    public func addAll(in repository: URL) throws {
        try execute("addAll") { try $0.addAll(in: repository) }
    }

    public func stageFiles(_ filePaths: [String], in repository: URL) throws {
        try execute("stageFiles") { try $0.stageFiles(filePaths, in: repository) }
    }

    public func unstageFiles(_ filePaths: [String], in repository: URL) throws {
        try execute("unstageFiles") { try $0.unstageFiles(filePaths, in: repository) }
    }

    public func discardFileChanges(_ filePath: String, in repository: URL) throws {
        try execute("discardFileChanges") { try $0.discardFileChanges(filePath, in: repository) }
    }

    public func discardFiles(_ filePaths: [String], in repository: URL) throws {
        try execute("discardFiles") { try $0.discardFiles(filePaths, in: repository) }
    }

    public func discardAllChanges(in repository: URL) throws {
        try execute("discardAllChanges") { try $0.discardAllChanges(in: repository) }
    }

    public func commit(message: String, in repository: URL) throws -> String {
        try execute("commit") { try $0.commit(message: message, in: repository) }
    }

    public func push(in repository: URL) throws -> String {
        try execute("push") { try $0.push(in: repository) }
    }

    public func listRemotes(in repository: URL) -> [GitRemoteSummary] {
        primaryBackendOrNil()?.listRemotes(in: repository) ?? []
    }

    public func addRemote(name: String, url: String, in repository: URL) throws {
        try execute("addRemote") { try $0.addRemote(name: name, url: url, in: repository) }
    }

    public func removeRemote(name: String, in repository: URL) throws {
        try execute("removeRemote") { try $0.removeRemote(name: name, in: repository) }
    }

    public func fetch(in repository: URL) throws {
        try execute("fetch") { try $0.fetch(in: repository) }
    }

    public func pull(in repository: URL) throws {
        try execute("pull") { try $0.pull(in: repository) }
    }

    public func pull(in repository: URL, strategy: GitRemoteOperation.PullStrategy) throws {
        try execute("pull") { try $0.pull(in: repository, strategy: strategy) }
    }

    public func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus {
        try execute("synchronize") { try $0.synchronize(in: repository) }
    }

    public func webLink(for url: String) -> URL? {
        primaryBackendOrNil()?.webLink(for: url)
    }

    public func isMerging(in repository: URL) -> Bool {
        primaryBackendOrNil()?.isMerging(in: repository) ?? false
    }

    public func hasConflictOperation(in repository: URL) -> Bool {
        primaryBackendOrNil()?.hasConflictOperation(in: repository) ?? false
    }

    public func conflictFiles(in repository: URL) -> [String] {
        primaryBackendOrNil()?.conflictFiles(in: repository) ?? []
    }

    public func mergeBranches(repository: URL, sourceBranch: String, targetBranch: String) throws -> String {
        try execute("mergeBranches") { try $0.mergeBranches(
            repository: repository,
            sourceBranch: sourceBranch,
            targetBranch: targetBranch
        ) }
    }

    public func mergeFileContent(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String {
        try execute("mergeFileContent") { try $0.mergeFileContent(path: path, version: version, in: repository) }
    }

    public func mergeFileDiff(path: String, in repository: URL) throws -> String {
        try execute("mergeFileDiff") { try $0.mergeFileDiff(path: path, in: repository) }
    }

    public func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws {
        try execute("checkoutMergeFileVersion") { try $0.checkoutMergeFileVersion(path: path, version: version, in: repository) }
    }

    public func continueMerge(in repository: URL) throws -> String {
        try execute("continueMerge") { try $0.continueMerge(in: repository) }
    }

    public func abortMerge(in repository: URL) throws -> String {
        try execute("abortMerge") { try $0.abortMerge(in: repository) }
    }

    public func finalizeMergeIfNeeded(in repository: URL) throws -> String? {
        try execute("finalizeMergeIfNeeded") { try $0.finalizeMergeIfNeeded(in: repository) }
    }
}
