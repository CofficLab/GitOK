import Foundation
import KitGit
@testable import ProviderGit

// MARK: - Controllable backend stub

/// A minimal `GitBackendProviding` double whose every operation is scriptable.
///
/// Only the non-defaulted protocol members are implemented; the rest come from
/// the `GitOperationProviding` extension. Scripting happens through `handler`,
/// which lets a test decide per-operation behaviour (success, "unsupported", or
/// a hard failure) without a stub per method.
final class ScriptedGitBackend: GitBackendProviding, @unchecked Sendable {
    struct ScriptError: Error, Equatable {
        var backendID: String
    }

    let descriptor: GitBackendDescriptor
    let isAvailable: Bool

    private let lock = NSLock()
    private var _calls: [(operation: String, repository: URL)] = []

    /// Maps an operation name to the behaviour of that operation.
    /// A `nil` entry means "return the type's neutral value".
    var handlers: [String: @Sendable (Any) throws -> Any?] = [:]

    init(descriptor: GitBackendDescriptor, isAvailable: Bool = true) {
        self.descriptor = descriptor
        self.isAvailable = isAvailable
    }

    static func makeBackend(
        id: String,
        priority: Int,
        isAvailable: Bool = true,
        name: String? = nil
    ) -> ScriptedGitBackend {
        ScriptedGitBackend(
            descriptor: GitBackendDescriptor(
                id: id,
                pluginID: "test.plugin.\(id)",
                name: name ?? id,
                priority: priority
            ),
            isAvailable: isAvailable
        )
    }

    /// Operation names recorded in call order.
    var calls: [(operation: String, repository: URL)] {
        lock.lock(); defer { lock.unlock() }
        return _calls
    }

    var calledOperations: [String] { calls.map(\.operation) }

    private func record(_ operation: String, _ repository: URL) throws -> Any? {
        lock.lock()
        _calls.append((operation, repository))
        let handler = handlers[operation]
        lock.unlock()
        return try handler?(repository)
    }

    /// Records an operation whose primary argument is a string rather than a URL.
    ///
    /// A few `primaryBackendOrNil()` methods take a remote URL or web URL, so
    /// they need their own recording path; the sentinel repository keeps the
    /// call log uniform.
    private func record(_ operation: String, _ subject: String) throws -> Any? {
        lock.lock()
        _calls.append((operation, URL(fileURLWithPath: subject)))
        let handler = handlers[operation]
        lock.unlock()
        return try handler?(subject)
    }

    private func value<T>(_ operation: String, _ repository: URL, _ fallback: T) throws -> T {
        guard let raw = try record(operation, repository), let typed = raw as? T else {
            return fallback
        }
        return typed
    }

    private func fails(_ operation: String, _ repository: URL) throws {
        _ = try record(operation, repository)
    }

    // MARK: - Read operations routed by DefaultGitProvider

    func loadCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] {
        try value("loadCommits", repository, [GitCommit]())
    }

    func loadAllCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] {
        try value("loadAllCommits", repository, [GitCommit]())
    }

    func countCommits(in repository: URL) throws -> Int {
        try value("countCommits", repository, 0)
    }

    func unpushedCommitHashes(in repository: URL) throws -> Set<String> {
        try value("unpushedCommitHashes", repository, Set<String>())
    }

    func loadStatus(in repository: URL) throws -> GitWorktreeStatus {
        try value("loadStatus", repository, GitWorktreeStatus(isClean: true, changeCount: 0, branch: nil))
    }

    func loadEntries(in repository: URL) throws -> [GitStatusEntry] {
        try value("loadEntries", repository, [GitStatusEntry]())
    }

    func loadWorktreeSnapshot(in repository: URL) throws -> GitWorktreeSnapshot {
        try value("loadWorktreeSnapshot", repository, GitWorktreeSnapshot(entries: [], branch: nil))
    }

    func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange] {
        try value("loadChanges", repository, [GitFileChange]())
    }

    func countCommitChanges(commit hash: String, in repository: URL) throws -> Int {
        try value("countCommitChanges", repository, 0)
    }

    func loadCommitChangesPage(
        commit hash: String,
        limit: Int,
        offset: Int,
        in repository: URL
    ) throws -> GitFileChangePage {
        try value("loadCommitChangesPage", repository, GitFileChangePage(offset: offset, changes: [], hasMore: false))
    }

    func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String {
        try value("loadDiff", repository, "")
    }

    func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String {
        try value("loadWorktreeDiff", repository, "")
    }

    func loadBlobData(commit: String, filePath: String, in repository: URL) throws -> Data {
        try value("loadBlobData", repository, Data())
    }

    func loadWorktreeFileData(filePath: String, in repository: URL) throws -> Data {
        try value("loadWorktreeFileData", repository, Data())
    }

    // MARK: - Non-defaulted members

    func currentBranch(in repository: URL) -> String? {
        (try? value("currentBranch", repository, String?.none)) ?? nil
    }

    func latestTag(in repository: URL) -> String? {
        (try? value("latestTag", repository, String?.none)) ?? nil
    }

    func firstCommitDate(in repository: URL) -> Date? {
        (try? value("firstCommitDate", repository, Date?.none)) ?? nil
    }

    func hasRemotes(in repository: URL) -> Bool { (try? value("hasRemotes", repository, false)) ?? false }

    func unpulledCount(in repository: URL) -> Int? { (try? value("unpulledCount", repository, Int?.none)) ?? nil }

    func unpushedCount(in repository: URL) -> Int? {
        (try? value("unpushedCount", repository, Int?.none)) ?? nil
    }

    func listBranches(in repository: URL) throws -> [GitBranchSummary] {
        try value("listBranches", repository, [GitBranchSummary]())
    }

    func createBranch(named name: String, in repository: URL) throws { try fails("createBranch", repository) }

    func checkoutBranch(named name: String, in repository: URL) throws { try fails("checkoutBranch", repository) }

    func checkoutRemoteBranch(
        named remoteBranch: String,
        as localBranch: String?,
        in repository: URL
    ) throws { try fails("checkoutRemoteBranch", repository) }

    func deleteBranch(named name: String, in repository: URL) throws { try fails("deleteBranch", repository) }

    func renameBranch(from currentName: String, to newName: String, in repository: URL) throws {
        try fails("renameBranch", repository)
    }

    func setUpstream(localBranch: String, upstreamBranch: String, in repository: URL) throws {
        try fails("setUpstream", repository)
    }

    func unsetUpstream(localBranch: String, in repository: URL) throws { try fails("unsetUpstream", repository) }

    func publishBranch(localBranch: String, remote: String, remoteBranch: String?, in repository: URL) throws {
        try fails("publishBranch", repository)
    }

    func deleteRemoteBranch(named branchName: String, remote: String, in repository: URL) throws {
        try fails("deleteRemoteBranch", repository)
    }

    func compareBranches(base: String, head: String, in repository: URL) throws -> GitBranchCompare {
        try value(
            "compareBranches",
            repository,
            GitBranchCompare(base: base, head: head, ahead: 0, behind: 0, commits: [], files: [])
        )
    }

    func undoCommit(_ commitHash: String, parentHash: String, in repository: URL) throws -> String {
        try value("undoCommit", repository, "")
    }

    func revertCommit(_ commitHash: String, in repository: URL) throws -> String {
        try value("revertCommit", repository, "")
    }

    func softReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try value("softReset", repository, "")
    }

    func mixedReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try value("mixedReset", repository, "")
    }

    func hardReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try value("hardReset", repository, "")
    }

    func squash(
        to targetHash: String,
        parentHash: String,
        expectedHead: String,
        message: String,
        in repository: URL
    ) throws -> String { try value("squash", repository, "") }

    func createLightweightTag(named name: String, at commitHash: String, in repository: URL) throws -> String {
        try value("createLightweightTag", repository, "")
    }

    func createAnnotatedTag(
        named name: String,
        at commitHash: String,
        message: String,
        in repository: URL
    ) throws -> String { try value("createAnnotatedTag", repository, "") }

    func deleteLocalTag(named name: String, in repository: URL) throws -> String {
        try value("deleteLocalTag", repository, "")
    }

    func pushTag(named name: String, remote: String, in repository: URL) throws -> String {
        try value("pushTag", repository, "")
    }

    func deleteRemoteTag(named name: String, remote: String, in repository: URL) throws -> String {
        try value("deleteRemoteTag", repository, "")
    }

    func listStashes(in repository: URL) -> [GitStashEntry] {
        (try? value("listStashes", repository, [GitStashEntry]())) ?? []
    }

    func hasChangesToStash(in repository: URL) -> Bool {
        (try? value("hasChangesToStash", repository, false)) ?? false
    }

    func saveStash(message: String?, in repository: URL) throws { try fails("saveStash", repository) }

    func applyStash(_ entry: GitStashEntry, in repository: URL) throws { try fails("applyStash", repository) }

    func popStash(_ entry: GitStashEntry, in repository: URL) throws { try fails("popStash", repository) }

    func dropStash(_ entry: GitStashEntry, in repository: URL) throws { try fails("dropStash", repository) }

    func cherryPickStatus(in repository: URL) -> GitCherryPickStatus {
        (try? value("cherryPickStatus", repository, GitCherryPickStatus.inactive)) ?? .inactive
    }

    func cherryPick(commits: [String], onto branch: String?, in repository: URL) throws -> String {
        try value("cherryPick", repository, "")
    }

    func continueCherryPick(in repository: URL) throws -> String { try value("continueCherryPick", repository, "") }

    func abortCherryPick(in repository: URL) throws -> String { try value("abortCherryPick", repository, "") }

    func listSubmodules(in repository: URL) -> [GitSubmoduleSummary] {
        (try? value("listSubmodules", repository, [GitSubmoduleSummary]())) ?? []
    }

    func updateSubmodules(in repository: URL) throws { try fails("updateSubmodules", repository) }

    func validateCloneDestination(_ destination: URL) throws { try fails("validateCloneDestination", destination) }

    func defaultRepositoryName(from remoteURL: String) -> String? {
        (try? record("defaultRepositoryName", remoteURL).flatMap { $0 as? String }) ?? nil
    }

    func clone(remoteURL: String, destination: URL) throws -> URL {
        try value("clone", destination, destination)
    }

    func hasStagedChanges(in repository: URL) throws -> Bool { try value("hasStagedChanges", repository, false) }

    func addAll(in repository: URL) throws { try fails("addAll", repository) }

    func stageFiles(_ filePaths: [String], in repository: URL) throws { try fails("stageFiles", repository) }

    func unstageFiles(_ filePaths: [String], in repository: URL) throws { try fails("unstageFiles", repository) }

    func discardFileChanges(_ filePath: String, in repository: URL) throws {
        try fails("discardFileChanges", repository)
    }

    func discardFiles(_ filePaths: [String], in repository: URL) throws { try fails("discardFiles", repository) }

    func discardAllChanges(in repository: URL) throws { try fails("discardAllChanges", repository) }

    func commit(message: String, in repository: URL) throws -> String { try value("commit", repository, "") }

    func push(in repository: URL) throws -> String { try value("push", repository, "") }

    func listRemotes(in repository: URL) -> [GitRemoteSummary] {
        (try? value("listRemotes", repository, [GitRemoteSummary]())) ?? []
    }

    func addRemote(name: String, url: String, in repository: URL) throws { try fails("addRemote", repository) }

    func removeRemote(name: String, in repository: URL) throws { try fails("removeRemote", repository) }

    func fetch(in repository: URL) throws { try fails("fetch", repository) }

    func pull(in repository: URL) throws { try fails("pull", repository) }

    func pull(in repository: URL, strategy: GitRemoteOperation.PullStrategy) throws {
        try fails("pull", repository)
    }

    func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus {
        try value("synchronize", repository, .init(ahead: 0, behind: 0, hasUpstream: false))
    }

    func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus {
        (try? value(
            "remoteTrackingStatus",
            repository,
            GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
        )) ?? GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
    }

    func webLink(for url: String) -> URL? {
        (try? record("webLink", url).flatMap { $0 as? URL }) ?? nil
    }

    func isMerging(in repository: URL) -> Bool { (try? value("isMerging", repository, false)) ?? false }

    func hasConflictOperation(in repository: URL) -> Bool {
        (try? value("hasConflictOperation", repository, false)) ?? false
    }

    func conflictFiles(in repository: URL) -> [String] {
        (try? value("conflictFiles", repository, [String]())) ?? []
    }

    func mergeBranches(repository: URL, sourceBranch: String, targetBranch: String) throws -> String {
        try value("mergeBranches", repository, "")
    }

    func mergeFileContent(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String {
        try value("mergeFileContent", repository, "")
    }

    func mergeFileDiff(path: String, in repository: URL) throws -> String {
        try value("mergeFileDiff", repository, "")
    }

    func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws {
        try fails("checkoutMergeFileVersion", repository)
    }

    func continueMerge(in repository: URL) throws -> String { try value("continueMerge", repository, "") }

    func abortMerge(in repository: URL) throws -> String { try value("abortMerge", repository, "") }

    func finalizeMergeIfNeeded(in repository: URL) throws -> String? {
        try value("finalizeMergeIfNeeded", repository, String?.none)
    }
}
