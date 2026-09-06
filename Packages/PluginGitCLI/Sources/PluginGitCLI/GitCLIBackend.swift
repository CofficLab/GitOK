import Foundation
import KitGit
import ProviderGit

/// 使用系统 `git` 命令实现 Git Provider 的后端。
///
/// KitGit 目前仍保留原有的 CLI 操作实现；这里将它适配到 Provider 契约，
/// 让业务插件不再需要知道这些静态操作类型。后续 LibGit2 插件实现同一
/// `GitBackendProviding`，即可在路由器层切换实现。
final class GitCLIBackend: @unchecked Sendable, GitBackendProviding {
    let descriptor = GitBackendDescriptor(
        id: "com.coffic.gitok.git-backend.cli",
        name: "Git CLI",
        version: "1.0.0"
    )

    func loadCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] {
        try GitCommitLoader.loadCommits(in: repository, limit: limit, offset: offset)
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

    func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String {
        try GitDiffLoader.loadDiff(commit: hash, filePath: filePath, in: repository)
    }

    func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String {
        try GitDiffLoader.loadWorktreeDiff(filePath: filePath, in: repository)
    }

    func currentBranch(in repository: URL) -> String? {
        GitRefReader.currentBranch(in: repository)
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

    func deleteBranch(named name: String, in repository: URL) throws {
        try GitBranchOperation.deleteBranch(named: name, in: repository)
    }

    func renameBranch(from currentName: String, to newName: String, in repository: URL) throws {
        try GitBranchOperation.renameBranch(from: currentName, to: newName, in: repository)
    }

    func compareBranches(base: String, head: String, in repository: URL) throws -> GitBranchCompare {
        try GitBranchOperation.compareBranches(base: base, head: head, in: repository)
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
