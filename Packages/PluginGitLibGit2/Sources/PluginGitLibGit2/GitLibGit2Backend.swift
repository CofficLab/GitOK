import Foundation
import KitGit
import LibGit2Swift
import ProviderGit

/// 使用 LibGit2Swift 实现 Git Provider 的后端。
final class GitLibGit2Backend: @unchecked Sendable, GitBackendProviding {
    let descriptor = GitBackendCatalog.libGit2

    func loadCommits(in repository: URL, limit: Int, offset: Int) throws -> [KitGit.GitCommit] {
        try LibGit2.getCommitList(at: repository.path, limit: limit, skip: offset).map { value in
            KitGit.GitCommit(
                hash: value.hash,
                shortHash: String(value.hash.prefix(7)),
                message: value.message,
                author: value.author,
                authorEmail: value.email,
                date: value.date,
                parentHashes: value.parentHashes,
                tags: value.tags
            )
        }
    }

    func unpushedCommitHashes(in repository: URL) throws -> Set<String> {
        try Set(LibGit2.getUnPushedCommits(at: repository.path, verbose: false).map(\.hash))
    }

    func loadStatus(in repository: URL) throws -> GitWorktreeStatus {
        let entries = try loadEntries(in: repository)
        return GitWorktreeStatus(
            isClean: entries.isEmpty,
            changeCount: entries.count,
            branch: currentBranch(in: repository)
        )
    }

    func loadEntries(in repository: URL) throws -> [GitStatusEntry] {
        let output = try LibGit2.getStatus(at: repository.path, verbose: false)
        return output.split(separator: "\n", omittingEmptySubsequences: true).compactMap { line in
            let value = String(line)
            guard value.count >= 4 else { return nil }
            let start = value.startIndex
            let x = value[start]
            let y = value[value.index(after: start)]
            let pathStart = value.index(start, offsetBy: 3)
            let rawPath = String(value[pathStart...])
            let path = rawPath.components(separatedBy: " -> ").last ?? rawPath
            return GitStatusEntry(path: path, stagedStatus: x, worktreeStatus: y)
        }
    }

    func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange] {
        try LibGit2.getCommitDiffFiles(atCommit: hash, at: repository.path).map { file in
            let status = GitFileChange.Status(rawValue: String(file.changeType.prefix(1))) ?? .unknown
            let (added, deleted) = Self.lineCounts(in: file.diff)
            let paths = file.file.components(separatedBy: " -> ")
            return GitFileChange(
                path: paths.last ?? file.file,
                status: status,
                addedLines: added,
                deletedLines: deleted,
                oldPath: paths.count == 2 ? paths.first : nil
            )
        }
    }

    func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String {
        try LibGit2.getFileDiff(atCommit: hash, for: filePath, at: repository.path)
    }

    func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String {
        let staged = try LibGit2.getFileDiff(for: filePath, at: repository.path, staged: true)
        let unstaged = try LibGit2.getFileDiff(for: filePath, at: repository.path, staged: false)
        return [staged, unstaged].filter { !$0.isEmpty }.joined(separator: "\n")
    }

    func currentBranch(in repository: URL) -> String? {
        try? LibGit2.getCurrentBranchInfo(at: repository.path)?.name
    }

    func unpushedCount(in repository: URL) -> Int? {
        try? LibGit2.getUnPushedCommits(at: repository.path, verbose: false).count
    }

    func hasRemotes(in repository: URL) -> Bool {
        (try? LibGit2.getRemoteList(at: repository.path).isEmpty) == false
    }

    func unpulledCount(in repository: URL) -> Int? {
        try? LibGit2.getUnPulledCount(at: repository.path)
    }

    func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus {
        guard let status = try? LibGit2.aheadBehind(at: repository.path), status.hasUpstream else {
            return GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
        }
        return GitRefReader.RemoteTrackingStatus(
            ahead: status.ahead,
            behind: status.behind,
            hasUpstream: true
        )
    }

    func listBranches(in repository: URL) throws -> [GitBranchSummary] {
        let local = try LibGit2.getLocalBranches(at: repository.path).map {
            GitBranchSummary(name: $0.name, isRemote: false, isCurrent: $0.isCurrent)
        }
        let remote = try LibGit2.getRemoteBranches(at: repository.path).map {
            GitBranchSummary(name: $0.id, isRemote: true, isCurrent: false)
        }
        return local + remote.filter { !$0.name.hasSuffix("/HEAD") }
    }

    func createBranch(named name: String, in repository: URL) throws {
        _ = try LibGit2.createBranch(named: name, at: repository.path)
    }

    func checkoutBranch(named name: String, in repository: URL) throws {
        try LibGit2.checkout(branch: name, at: repository.path)
    }

    func deleteBranch(named name: String, in repository: URL) throws {
        try LibGit2.deleteBranch(named: name, at: repository.path)
    }

    func renameBranch(from currentName: String, to newName: String, in repository: URL) throws {
        try LibGit2.renameBranch(named: currentName, to: newName, at: repository.path)
    }

    func setUpstream(localBranch: String, upstreamBranch: String, in repository: URL) throws {
        try LibGit2.setUpstream(localBranch: localBranch, upstreamBranch: upstreamBranch, at: repository.path)
    }

    func unsetUpstream(localBranch: String, in repository: URL) throws {
        try LibGit2.unsetUpstream(localBranch: localBranch, at: repository.path)
    }

    func publishBranch(localBranch: String, remote: String, remoteBranch: String?, in repository: URL) throws {
        try LibGit2.publishBranch(
            localBranch: localBranch,
            remote: remote,
            remoteBranch: remoteBranch,
            at: repository.path,
            setUpstream: true,
            verbose: false
        )
    }

    func deleteRemoteBranch(named branchName: String, remote: String, in repository: URL) throws {
        try LibGit2.deleteRemoteBranch(named: branchName, remote: remote, at: repository.path, verbose: false)
    }

    func compareBranches(base: String, head: String, in repository: URL) throws -> KitGit.GitBranchCompare {
        let result = try LibGit2.compareBranches(base: base, head: head, at: repository.path)
        return KitGit.GitBranchCompare(
            base: result.base,
            head: result.head,
            ahead: result.ahead,
            behind: result.behind,
            commits: result.commits.map {
                KitGit.GitBranchCompareCommit(hash: $0.hash, author: $0.author, date: $0.date, subject: $0.subject)
            },
            files: result.files.map {
                KitGit.GitBranchCompareFile(status: $0.status, path: $0.path, oldPath: $0.oldPath)
            }
        )
    }

    func hasStagedChanges(in repository: URL) throws -> Bool {
        try !LibGit2.getDiffFileList(at: repository.path, staged: true).isEmpty
    }

    func addAll(in repository: URL) throws {
        try LibGit2.addFiles([], at: repository.path)
    }

    func stageFiles(_ filePaths: [String], in repository: URL) throws {
        try LibGit2.addFiles(filePaths, at: repository.path)
    }

    func unstageFiles(_ filePaths: [String], in repository: URL) throws {
        for filePath in filePaths {
            let patch = try LibGit2.getFileDiff(for: filePath, at: repository.path, staged: true)
            if !patch.isEmpty { try LibGit2.applyPatch(patch, mode: .unstage, at: repository.path) }
        }
    }

    func discardFileChanges(_ filePath: String, in repository: URL) throws {
        try LibGit2.checkoutFile(filePath, at: repository.path)
    }

    func discardFiles(_ filePaths: [String], in repository: URL) throws {
        try LibGit2.checkoutFiles(filePaths, at: repository.path)
    }

    func commit(message: String, in repository: URL) throws -> String {
        try LibGit2.createCommit(message: message, at: repository.path, verbose: false)
    }

    func push(in repository: URL) throws -> String {
        try LibGit2.push(at: repository.path, verbose: false)
        return "Push completed."
    }

    func listRemotes(in repository: URL) -> [GitRemoteSummary] {
        (try? LibGit2.getRemoteList(at: repository.path).map {
            GitRemoteSummary(name: $0.name, url: $0.url, fetchURL: $0.fetchURL, pushURL: $0.pushURL)
        }) ?? []
    }

    func addRemote(name: String, url: String, in repository: URL) throws {
        try LibGit2.addRemote(name: name, url: url, at: repository.path, verbose: false)
    }

    func removeRemote(name: String, in repository: URL) throws {
        try LibGit2.removeRemote(name: name, at: repository.path, verbose: false)
    }

    func fetch(in repository: URL) throws {
        try LibGit2.fetch(at: repository.path, verbose: false)
    }

    func pull(in repository: URL) throws {
        try LibGit2.pull(at: repository.path, verbose: false)
    }

    func pull(in repository: URL, strategy: GitRemoteOperation.PullStrategy) throws {
        // LibGit2Swift currently exposes the repository's normal merge pull. The
        // provider keeps the same operation boundary for both pull strategies.
        try LibGit2.pull(at: repository.path, verbose: false)
    }

    func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus {
        try fetch(in: repository)
        var status = remoteTrackingStatus(in: repository)
        if status.behind > 0 { try pull(in: repository) }
        status = remoteTrackingStatus(in: repository)
        if status.ahead > 0 { _ = try push(in: repository) }
        return remoteTrackingStatus(in: repository)
    }

    func webLink(for url: String) -> URL? {
        let normalized: String
        if url.hasPrefix("git@"), let separator = url.firstIndex(of: ":") {
            let host = url[url.index(url.startIndex, offsetBy: 4)..<separator]
            let path = url[url.index(after: separator)...]
            normalized = "https://\(host)/\(path)".replacingOccurrences(of: ".git", with: "")
        } else {
            normalized = url.replacingOccurrences(of: ".git", with: "")
        }
        guard let value = URL(string: normalized) else { return nil }
        return value.pathComponents.count >= 2 ? value : nil
    }

    func isMerging(in repository: URL) -> Bool {
        FileManager.default.fileExists(atPath: repository.appendingPathComponent(".git/MERGE_HEAD").path)
    }

    func hasConflictOperation(in repository: URL) -> Bool {
        isMerging(in: repository) || !conflictFiles(in: repository).isEmpty
    }

    func conflictFiles(in repository: URL) -> [String] {
        (try? loadEntries(in: repository))?.compactMap { entry in
            entry.stagedStatus == "U" || entry.worktreeStatus == "U" ? entry.path : nil
        } ?? []
    }

    func mergeBranches(repository: URL, sourceBranch: String, targetBranch: String) throws -> String {
        try LibGit2.checkout(branch: targetBranch, at: repository.path)
        try LibGit2.merge(branchName: sourceBranch, at: repository.path, verbose: false)
        return "Merge completed."
    }

    func mergeFileContent(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String {
        guard isMerging(in: repository) else { throw GitProviderError.backendOperationUnsupported("No merge is in progress.") }
        switch version {
        case .ours:
            guard let hash = try LibGit2.getCurrentBranchInfo(at: repository.path)?.latestCommitHash else {
                throw GitProviderError.backendOperationUnsupported("The current commit is unavailable.")
            }
            return try LibGit2.getFileContent(atCommit: hash, file: path, at: repository.path)
        case .theirs:
            return try LibGit2.getFileContent(atCommit: mergeHeadHash(in: repository), file: path, at: repository.path)
        case .base:
            throw GitProviderError.backendOperationUnsupported("LibGit2Swift does not expose the merge-base file API.")
        }
    }

    func mergeFileDiff(path: String, in repository: URL) throws -> String {
        try LibGit2.getFileDiff(for: path, at: repository.path, staged: false)
    }

    func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws {
        let content = try mergeFileContent(path: path, version: version, in: repository)
        let fileURL = repository.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        try stageFiles([path], in: repository)
    }

    func continueMerge(in repository: URL) throws -> String {
        let hash = try mergeHeadHash(in: repository)
        try LibGit2.continueMerge(branchName: hash, at: repository.path, verbose: false)
        return "Merge continued."
    }

    func abortMerge(in repository: URL) throws -> String {
        try LibGit2.abortMerge(at: repository.path, verbose: false)
        return "Merge aborted."
    }

    func finalizeMergeIfNeeded(in repository: URL) throws -> String? {
        guard isMerging(in: repository), conflictFiles(in: repository).isEmpty else { return nil }
        return try continueMerge(in: repository)
    }

    private func mergeHeadHash(in repository: URL) throws -> String {
        let gitDirectory = repository.appendingPathComponent(".git")
        let url = gitDirectory.appendingPathComponent("MERGE_HEAD")
        let value = try String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw GitProviderError.backendOperationUnsupported("The merge head is unavailable.") }
        return value
    }

    private static func lineCounts(in diff: String) -> (Int, Int) {
        var added = 0
        var deleted = 0
        for line in diff.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("+++") || line.hasPrefix("---") { continue }
            if line.hasPrefix("+") { added += 1 }
            if line.hasPrefix("-") { deleted += 1 }
        }
        return (added, deleted)
    }
}
