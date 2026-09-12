import Foundation
import KitGit
import ProviderGit

/// 使用系统 `git` 命令实现 Git Provider 的后端。
///
/// KitGit 目前仍保留原有的 CLI 操作实现；这里将它适配到 Provider 契约，
/// 让业务插件不再需要知道这些静态操作类型。后续 LibGit2 插件实现同一
/// `GitBackendProviding`，即可在路由器层切换实现。
final class GitCLIBackend: @unchecked Sendable, GitBackendProviding {
    let descriptor = GitBackendCatalog.cli

    var isAvailable: Bool {
        GitProcessRunner.isAvailable
    }

    func loadCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] {
        try GitCommitLoader.loadCommits(in: repository, limit: limit, offset: offset)
    }

    func loadAllCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] {
        try GitCommitLoader.loadCommits(in: repository, limit: limit, offset: offset, allRefs: true)
    }

    func countCommits(in repository: URL) throws -> Int {
        try GitCommitLoader.countCommits(in: repository)
    }

    func unpushedCommitHashes(in repository: URL) throws -> Set<String> {
        try GitCommitLoader.unpushedCommitHashes(in: repository)
    }

    func loadStatus(in repository: URL) throws -> GitWorktreeStatus {
        try GitStatusLoader.loadStatus(in: repository)
    }

    func loadEntries(in repository: URL) throws -> [GitStatusEntry] {
        try GitStatusLoader.loadEntries(in: repository)
    }

    func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange] {
        try GitDiffLoader.loadChanges(commit: hash, in: repository)
    }

    func countCommitChanges(commit hash: String, in repository: URL) throws -> Int {
        try GitDiffLoader.countChanges(commit: hash, in: repository)
    }

    func loadCommitChangesPage(
        commit hash: String,
        limit: Int,
        offset: Int,
        in repository: URL
    ) throws -> GitFileChangePage {
        try GitDiffLoader.loadChangesPage(
            commit: hash,
            limit: limit,
            offset: offset,
            in: repository
        )
    }

    func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String {
        try GitDiffLoader.loadDiff(commit: hash, filePath: filePath, in: repository)
    }

    func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String {
        try GitDiffLoader.loadWorktreeDiff(filePath: filePath, in: repository)
    }

    func currentBranch(in repository: URL) -> String? {
        GitRefReader.currentBranch(in: repository)
    }

    func latestTag(in repository: URL) -> String? {
        GitRefReader.latestTag(in: repository)
    }

    func firstCommitDate(in repository: URL) -> Date? {
        GitRefReader.firstCommitDate(in: repository)
    }

    func unpushedCount(in repository: URL) -> Int? {
        GitRefReader.unpushedCount(in: repository)
    }

    func hasRemotes(in repository: URL) -> Bool {
        GitRefReader.hasRemotes(in: repository)
    }

    func unpulledCount(in repository: URL) -> Int? {
        GitRefReader.unpulledCount(in: repository)
    }

    func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus {
        GitRefReader.remoteTrackingStatus(in: repository)
    }

    func listBranches(in repository: URL) throws -> [GitBranchSummary] {
        try GitBranchOperation.listBranches(in: repository)
    }

    func createBranch(named name: String, in repository: URL) throws {
        try GitBranchOperation.createBranch(named: name, in: repository)
    }

    func checkoutBranch(named name: String, in repository: URL) throws {
        try GitBranchOperation.checkoutBranch(named: name, in: repository)
    }

    func checkoutRemoteBranch(
        named remoteBranch: String,
        as localBranch: String?,
        in repository: URL
    ) throws {
        try GitBranchOperation.checkoutRemoteBranch(
            named: remoteBranch,
            as: localBranch,
            in: repository
        )
    }

    func deleteBranch(named name: String, in repository: URL) throws {
        try GitBranchOperation.deleteBranch(named: name, in: repository)
    }

    func renameBranch(from currentName: String, to newName: String, in repository: URL) throws {
        try GitBranchOperation.renameBranch(from: currentName, to: newName, in: repository)
    }

    func setUpstream(localBranch: String, upstreamBranch: String, in repository: URL) throws {
        try GitBranchOperation.setUpstream(localBranch: localBranch, upstreamBranch: upstreamBranch, in: repository)
    }

    func unsetUpstream(localBranch: String, in repository: URL) throws {
        try GitBranchOperation.unsetUpstream(localBranch: localBranch, in: repository)
    }

    func publishBranch(localBranch: String, remote: String, remoteBranch: String?, in repository: URL) throws {
        try GitBranchOperation.publishBranch(localBranch: localBranch, remote: remote, remoteBranch: remoteBranch, in: repository)
    }

    func deleteRemoteBranch(named branchName: String, remote: String, in repository: URL) throws {
        try GitBranchOperation.deleteRemoteBranch(named: branchName, remote: remote, in: repository)
    }

    func compareBranches(base: String, head: String, in repository: URL) throws -> GitBranchCompare {
        try GitBranchOperation.compareBranches(base: base, head: head, in: repository)
    }

    func undoCommit(_ commitHash: String, parentHash: String, in repository: URL) throws -> String {
        try GitHistoryOperation.undoCommit(commitHash, parentHash: parentHash, in: repository)
    }

    func revertCommit(_ commitHash: String, in repository: URL) throws -> String {
        try GitHistoryOperation.revertCommit(commitHash, in: repository)
    }

    func softReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try GitHistoryOperation.softReset(to: targetHash, expectedHead: expectedHead, in: repository)
    }

    func mixedReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try GitHistoryOperation.mixedReset(to: targetHash, expectedHead: expectedHead, in: repository)
    }

    func hardReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try GitHistoryOperation.hardReset(to: targetHash, expectedHead: expectedHead, in: repository)
    }

    func squash(to targetHash: String, parentHash: String, expectedHead: String, message: String, in repository: URL) throws -> String {
        try GitHistoryOperation.squash(to: targetHash, parentHash: parentHash, expectedHead: expectedHead, message: message, in: repository)
    }

    func createLightweightTag(named name: String, at commitHash: String, in repository: URL) throws -> String {
        try GitTagOperation.createLightweight(named: name, at: commitHash, in: repository)
    }

    func createAnnotatedTag(named name: String, at commitHash: String, message: String, in repository: URL) throws -> String {
        try GitTagOperation.createAnnotated(named: name, at: commitHash, message: message, in: repository)
    }

    func deleteLocalTag(named name: String, in repository: URL) throws -> String {
        try GitTagOperation.deleteLocal(named: name, in: repository)
    }

    func pushTag(named name: String, remote: String, in repository: URL) throws -> String {
        try GitTagOperation.push(named: name, remote: remote, in: repository)
    }

    func deleteRemoteTag(named name: String, remote: String, in repository: URL) throws -> String {
        try GitTagOperation.deleteRemote(named: name, remote: remote, in: repository)
    }

    func listStashes(in repository: URL) -> [GitStashEntry] {
        GitStashOperation.list(in: repository)
    }

    func hasChangesToStash(in repository: URL) -> Bool {
        GitStashOperation.hasChanges(in: repository)
    }

    func saveStash(message: String?, in repository: URL) throws {
        try GitStashOperation.save(message: message, in: repository)
    }

    func applyStash(_ entry: GitStashEntry, in repository: URL) throws {
        try GitStashOperation.apply(entry, in: repository)
    }

    func popStash(_ entry: GitStashEntry, in repository: URL) throws {
        try GitStashOperation.pop(entry, in: repository)
    }

    func dropStash(_ entry: GitStashEntry, in repository: URL) throws {
        try GitStashOperation.drop(entry, in: repository)
    }

    func cherryPickStatus(in repository: URL) -> GitCherryPickStatus {
        GitCherryPickOperation.status(in: repository)
    }

    func cherryPick(commits: [String], onto branch: String?, in repository: URL) throws -> String {
        try GitCherryPickOperation.cherryPick(commits: commits, onto: branch, in: repository)
    }

    func continueCherryPick(in repository: URL) throws -> String {
        try GitCherryPickOperation.continueCherryPick(in: repository)
    }

    func abortCherryPick(in repository: URL) throws -> String {
        try GitCherryPickOperation.abortCherryPick(in: repository)
    }

    func listSubmodules(in repository: URL) -> [GitSubmoduleSummary] {
        GitSubmoduleOperation.list(in: repository)
    }

    func updateSubmodules(in repository: URL) throws {
        GitSubmoduleOperation.updateAll(in: repository)
    }

    func validateCloneDestination(_ destination: URL) throws {
        try GitCloneOperation.validateDestination(destination)
    }

    func defaultRepositoryName(from remoteURL: String) -> String? {
        GitCloneOperation.defaultRepositoryName(from: remoteURL)
    }

    func clone(remoteURL: String, destination: URL) throws -> URL {
        try GitCloneOperation.clone(remoteURL: remoteURL, destination: destination)
    }

    func clone(
        remoteURL: String,
        destination: URL,
        progress: @escaping @Sendable (GitCloneProgress) -> Void
    ) throws -> URL {
        try GitCloneOperation.clone(
            remoteURL: remoteURL,
            destination: destination,
            onProgress: progress
        )
    }

    func clone(
        remoteURL: String,
        destination: URL,
        progress: @escaping @Sendable (GitCloneProgress) -> Void,
        cancellation: GitProcessCancellation?
    ) throws -> URL {
        try GitCloneOperation.clone(
            remoteURL: remoteURL,
            destination: destination,
            onProgress: progress,
            cancellation: cancellation
        )
    }

    func hasStagedChanges(in repository: URL) throws -> Bool {
        try GitCommitOperation.hasStagedChanges(in: repository)
    }

    func addAll(in repository: URL) throws {
        try GitCommitOperation.addAll(in: repository)
    }

    func stageFiles(_ filePaths: [String], in repository: URL) throws {
        try GitCommitOperation.stageFiles(filePaths, in: repository)
    }

    func unstageFiles(_ filePaths: [String], in repository: URL) throws {
        try GitCommitOperation.unstageFiles(filePaths, in: repository)
    }

    func discardFileChanges(_ filePath: String, in repository: URL) throws {
        try GitCommitOperation.discardFileChanges(filePath, in: repository)
    }

    func discardFiles(_ filePaths: [String], in repository: URL) throws {
        try GitCommitOperation.discardFiles(filePaths, in: repository)
    }

    func discardAllChanges(in repository: URL) throws {
        try GitCommitOperation.discardAllChanges(in: repository)
    }

    func commit(message: String, in repository: URL) throws -> String {
        try GitCommitOperation.commit(message: message, in: repository)
    }

    func push(in repository: URL) throws -> String {
        try GitCommitOperation.push(in: repository)
    }

    func listRemotes(in repository: URL) -> [GitRemoteSummary] {
        GitRemoteOperation.listRemotes(in: repository)
    }

    func addRemote(name: String, url: String, in repository: URL) throws {
        try GitRemoteOperation.addRemote(name: name, url: url, in: repository)
    }

    func removeRemote(name: String, in repository: URL) throws {
        try GitRemoteOperation.removeRemote(name: name, in: repository)
    }

    func fetch(in repository: URL) throws {
        try GitRemoteOperation.fetch(in: repository)
    }

    func pull(in repository: URL) throws {
        try GitRemoteOperation.pull(in: repository)
    }

    func pull(in repository: URL, strategy: GitRemoteOperation.PullStrategy) throws {
        try GitRemoteOperation.pull(in: repository, strategy: strategy)
    }

    func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus {
        try GitRemoteOperation.synchronize(in: repository)
    }

    func webLink(for url: String) -> URL? {
        GitRemoteOperation.webLink(for: url)
    }

    func isMerging(in repository: URL) -> Bool {
        GitMergeOperation.isMerging(in: repository)
    }

    func hasConflictOperation(in repository: URL) -> Bool {
        GitMergeOperation.hasConflictOperation(in: repository)
    }

    func conflictFiles(in repository: URL) -> [String] {
        GitMergeOperation.conflictFiles(in: repository)
    }

    func mergeBranches(repository: URL, sourceBranch: String, targetBranch: String) throws -> String {
        try GitMergeOperation.mergeBranches(
            repository: repository,
            sourceBranch: sourceBranch,
            targetBranch: targetBranch
        )
    }

    func mergeFileContent(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String {
        try GitMergeOperation.mergeFileContent(path: path, version: version, in: repository)
    }

    func mergeFileDiff(path: String, in repository: URL) throws -> String {
        try GitMergeOperation.mergeFileDiff(path: path, in: repository)
    }

    func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws {
        try GitMergeOperation.checkoutMergeFileVersion(path: path, version: version, in: repository)
    }

    func continueMerge(in repository: URL) throws -> String {
        try GitMergeOperation.continueMerge(in: repository)
    }

    func abortMerge(in repository: URL) throws -> String {
        try GitMergeOperation.abortMerge(in: repository)
    }

    func finalizeMergeIfNeeded(in repository: URL) throws -> String? {
        try GitMergeOperation.finalizeMergeIfNeeded(in: repository)
    }
}
