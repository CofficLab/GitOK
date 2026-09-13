import Foundation
import KitGit
import LibGit2Swift
import ProviderGit

private final class LibGit2CloneProgressTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var lastTimestamp = Date()
    private var lastBytes = 0
    private var bytesPerSecond = 0.0

    func progress(for value: LibGit2CloneProgress) -> GitCloneProgress {
        let now = Date()
        lock.lock()
        let elapsed = now.timeIntervalSince(lastTimestamp)
        let byteDelta = max(0, value.receivedBytes - lastBytes)
        if elapsed >= 0.1, byteDelta > 0 {
            let instantaneousRate = Double(byteDelta) / elapsed
            bytesPerSecond = bytesPerSecond == 0
                ? instantaneousRate
                : bytesPerSecond * 0.7 + instantaneousRate * 0.3
            lastTimestamp = now
            lastBytes = value.receivedBytes
        }
        let rate = bytesPerSecond
        lock.unlock()

        if value.totalObjects > 0, value.receivedObjects < value.totalObjects {
            let stageFraction = value.fractionCompleted
            let overallFraction = stageFraction.map { 0.05 + $0 * 0.65 }
            let percent = Int((stageFraction ?? 0) * 100)
            return GitCloneProgress(
                phase: .receivingObjects,
                fractionCompleted: overallFraction,
                detail: "Receiving objects: \(percent)% (\(value.receivedObjects)/\(value.totalObjects)), \(formatBytes(Double(value.receivedBytes))) | \(formatBytes(rate))/s"
            )
        }

        if value.totalDeltas > 0, value.indexedDeltas < value.totalDeltas {
            let stageFraction = min(max(Double(value.indexedDeltas) / Double(value.totalDeltas), 0), 1)
            return GitCloneProgress(
                phase: .resolvingDeltas,
                fractionCompleted: 0.70 + stageFraction * 0.20,
                detail: "Resolving deltas: \(Int(stageFraction * 100))% (\(value.indexedDeltas)/\(value.totalDeltas))"
            )
        }

        let stageFraction = value.fractionCompleted
        let overallFraction = stageFraction.map { 0.05 + $0 * 0.65 }
        let percent = Int((stageFraction ?? 0) * 100)
        return GitCloneProgress(
            phase: .receivingObjects,
            fractionCompleted: overallFraction,
            detail: "Receiving objects: \(percent)% (\(value.receivedObjects)/\(value.totalObjects)), \(formatBytes(Double(value.receivedBytes))) | \(formatBytes(rate))/s"
        )
    }

    private func formatBytes(_ bytes: Double) -> String {
        let units = ["B", "KiB", "MiB", "GiB"]
        var value = max(bytes, 0)
        var unitIndex = 0
        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        return String(
            format: "%.2f %@",
            locale: Locale(identifier: "en_US_POSIX"),
            value,
            units[unitIndex]
        )
    }
}

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

    func loadCommits(
        in repository: URL,
        limit: Int,
        offset: Int,
        cancellation: GitProcessCancellation?
    ) throws -> [KitGit.GitCommit] {
        // Project-switch-sensitive list reads must be cancellable and must not
        // wait behind LibGit2Swift's process-wide synchronous queue.
        try GitCommitLoader.loadCommits(
            in: repository,
            limit: limit,
            offset: offset,
            cancellation: cancellation
        )
    }

    func loadAllCommits(in repository: URL, limit: Int, offset: Int) throws -> [KitGit.GitCommit] {
        // LibGit2Swift's list API follows HEAD; use the shared CLI loader for
        // the explicit all-refs history required by the activity heatmap.
        try GitCommitLoader.loadCommits(in: repository, limit: limit, offset: offset, allRefs: true)
    }

    func countCommits(in repository: URL) throws -> Int {
        try GitCommitLoader.countCommits(in: repository)
    }

    func countCommits(in repository: URL, cancellation: GitProcessCancellation?) throws -> Int {
        try GitCommitLoader.countCommits(in: repository, cancellation: cancellation)
    }

    func unpushedCommitHashes(in repository: URL) throws -> Set<String> {
        try Set(LibGit2.getUnPushedCommits(at: repository.path, verbose: false).map(\.hash))
    }

    func unpushedCommitHashes(
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> Set<String> {
        try GitCommitLoader.unpushedCommitHashes(in: repository, cancellation: cancellation)
    }

    func loadStatus(in repository: URL) throws -> GitWorktreeStatus {
        // libgit2's recursive status scan runs on LibGit2Swift's process-wide
        // serial queue and has no cancellation or timeout. A scan left behind
        // by a previous project can therefore block status refreshes for the
        // newly selected repository. Keep this hot UI path bounded with the
        // CLI loader's command timeout; LibGit2Swift remains the primary
        // backend for the other Git operations.
        try GitStatusLoader.loadStatus(in: repository)
    }

    func loadEntries(in repository: URL) throws -> [GitStatusEntry] {
        try GitStatusLoader.loadEntries(in: repository)
    }

    func loadEntries(
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> [GitStatusEntry] {
        try GitStatusLoader.loadEntries(in: repository, cancellation: cancellation)
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

    // LibGit2Swift 当前公开的 diff API 会一次性生成完整文件数组；分页能力
    // 先复用 KitGit 的 NUL 流式读取，确保 Commit Detail 不因后端选择而失去
    // 有界内存特性。普通 diff 读取仍保持 LibGit2 实现。
    func countCommitChanges(commit hash: String, in repository: URL) throws -> Int {
        try GitDiffLoader.countChanges(commit: hash, in: repository)
    }

    func countCommitChanges(
        commit hash: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> Int {
        try GitDiffLoader.countChanges(commit: hash, in: repository, cancellation: cancellation)
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

    func loadCommitChangesPage(
        commit hash: String,
        limit: Int,
        offset: Int,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> GitFileChangePage {
        try GitDiffLoader.loadChangesPage(
            commit: hash,
            limit: limit,
            offset: offset,
            in: repository,
            cancellation: cancellation
        )
    }

    func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String {
        try LibGit2.getFileDiff(atCommit: hash, for: filePath, at: repository.path)
    }

    func loadDiff(
        commit hash: String,
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> String {
        try GitDiffLoader.loadDiff(
            commit: hash,
            filePath: filePath,
            in: repository,
            cancellation: cancellation
        )
    }

    func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String {
        let staged = try LibGit2.getFileDiff(for: filePath, at: repository.path, staged: true)
        let unstaged = try LibGit2.getFileDiff(for: filePath, at: repository.path, staged: false)
        return [staged, unstaged].filter { !$0.isEmpty }.joined(separator: "\n")
    }

    func loadWorktreeDiff(
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> String {
        try GitDiffLoader.loadWorktreeDiff(
            filePath: filePath,
            in: repository,
            cancellation: cancellation
        )
    }

    func currentBranch(in repository: URL) -> String? {
        try? LibGit2.getCurrentBranchInfo(at: repository.path)?.name
    }

    func latestTag(in repository: URL) -> String? {
        guard let description = try? LibGit2.describe(path: repository.path) else { return nil }
        return Self.tagName(from: description)
    }

    func firstCommitDate(in repository: URL) -> Date? {
        GitRefReader.firstCommitDate(in: repository)
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

    private static func tagName(from description: String) -> String? {
        let value = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        let parts = value.split(separator: "-")
        guard parts.count >= 3,
              parts[parts.count - 2].allSatisfy(\.isNumber),
              parts[parts.count - 1].hasPrefix("g") else {
            return value
        }
        return parts.dropLast(2).joined(separator: "-")
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

    func checkoutRemoteBranch(
        named remoteBranch: String,
        as localBranch: String?,
        in repository: URL
    ) throws {
        let remote = remoteBranch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let separator = remote.firstIndex(of: "/"), separator != remote.startIndex else {
            throw GitProviderError.backendOperationUnsupported(
                "A remote branch must include a remote name."
            )
        }

        let inferredLocal = String(remote[remote.index(after: separator)...])
        let local = (localBranch ?? inferredLocal).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !local.isEmpty else {
            throw GitProviderError.backendOperationUnsupported("A local branch name is required.")
        }

        let localBranches = try LibGit2.getLocalBranches(at: repository.path)
        guard !localBranches.contains(where: { $0.name == local }) else {
            throw GitProviderError.backendOperationUnsupported("Local branch already exists: \(local)")
        }

        let remoteBranches = try LibGit2.getRemoteBranches(at: repository.path)
        guard let remoteBranchInfo = remoteBranches.first(where: { $0.id == remote }),
              !remoteBranchInfo.latestCommitHash.isEmpty else {
            throw GitProviderError.backendOperationUnsupported("Remote branch not found: \(remote)")
        }

        // LibGit2Swift's public branch creator starts from HEAD rather than an
        // arbitrary ref. Move to the remote commit first, create the local
        // branch there, then set its upstream and switch to the local ref.
        let previousBranch = try? LibGit2.getCurrentBranchInfo(at: repository.path)?.name
        try LibGit2.checkoutCommit(remoteBranchInfo.latestCommitHash, at: repository.path)
        var createdLocalBranch = false
        do {
            _ = try LibGit2.createBranch(named: local, at: repository.path)
            createdLocalBranch = true
            try LibGit2.setUpstream(localBranch: local, upstreamBranch: remote, at: repository.path)
            try LibGit2.checkout(branch: local, at: repository.path)
        } catch {
            if createdLocalBranch {
                try? LibGit2.deleteBranch(named: local, at: repository.path)
            }
            if let previousBranch {
                try? LibGit2.checkout(branch: previousBranch, at: repository.path)
            }
            throw error
        }
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

    func undoCommit(_ commitHash: String, parentHash: String, in repository: URL) throws -> String {
        try validateExpectedHead(commitHash, in: repository)
        try LibGit2.reset(to: parentHash, mode: "mixed", at: repository.path, verbose: false)
        return "Undo completed."
    }

    func revertCommit(_ commitHash: String, in repository: URL) throws -> String {
        try LibGit2.revertCommit(commitHash, at: repository.path, verbose: false)
        return "Revert completed."
    }

    func softReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try validateExpectedHead(expectedHead, in: repository)
        try LibGit2.reset(to: targetHash, mode: "soft", at: repository.path, verbose: false)
        return "Soft reset completed."
    }

    func mixedReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try validateExpectedHead(expectedHead, in: repository)
        try LibGit2.reset(to: targetHash, mode: "mixed", at: repository.path, verbose: false)
        return "Mixed reset completed."
    }

    func hardReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String {
        try validateExpectedHead(expectedHead, in: repository)
        try LibGit2.reset(to: targetHash, mode: "hard", at: repository.path, verbose: false)
        return "Hard reset completed."
    }

    func squash(to targetHash: String, parentHash: String, expectedHead: String, message: String, in repository: URL) throws -> String {
        try validateExpectedHead(expectedHead, in: repository)
        try LibGit2.reset(to: parentHash, mode: "soft", at: repository.path, verbose: false)
        return try LibGit2.createCommit(message: message, at: repository.path, verbose: false)
    }

    func createLightweightTag(named name: String, at commitHash: String, in repository: URL) throws -> String {
        try LibGit2.createTag(named: name, at: commitHash, in: repository.path, verbose: false)
        return "Tag created."
    }

    func createAnnotatedTag(named name: String, at commitHash: String, message: String, in repository: URL) throws -> String {
        try LibGit2.createTag(named: name, message: message, at: commitHash, in: repository.path, verbose: false)
        return "Tag created."
    }

    func deleteLocalTag(named name: String, in repository: URL) throws -> String {
        try LibGit2.deleteTag(named: name, at: repository.path, verbose: false)
        return "Tag deleted."
    }

    func pushTag(named name: String, remote: String, in repository: URL) throws -> String {
        try LibGit2.pushTag(named: name, remote: remote, at: repository.path, verbose: false)
        return "Tag pushed."
    }

    func deleteRemoteTag(named name: String, remote: String, in repository: URL) throws -> String {
        try LibGit2.deleteRemoteTag(named: name, remote: remote, at: repository.path, verbose: false)
        return "Remote tag deleted."
    }

    func listStashes(in repository: URL) -> [KitGit.GitStashEntry] {
        (try? LibGit2.getStashList(at: repository.path).map {
            KitGit.GitStashEntry(index: $0.index, message: $0.message)
        }) ?? []
    }

    func hasChangesToStash(in repository: URL) -> Bool {
        !((try? loadEntries(in: repository)) ?? []).isEmpty
    }

    func saveStash(message: String?, in repository: URL) throws {
        _ = try LibGit2.stash(message: message, at: repository.path, verbose: false)
    }

    func applyStash(_ entry: KitGit.GitStashEntry, in repository: URL) throws {
        try LibGit2.stashApply(index: entry.index, at: repository.path, verbose: false)
    }

    func popStash(_ entry: KitGit.GitStashEntry, in repository: URL) throws {
        try LibGit2.stashPop(index: entry.index, at: repository.path, verbose: false)
    }

    func dropStash(_ entry: KitGit.GitStashEntry, in repository: URL) throws {
        try LibGit2.stashDrop(index: entry.index, at: repository.path, verbose: false)
    }

    func cherryPickStatus(in repository: URL) -> GitCherryPickStatus {
        let head = repository.appendingPathComponent(".git/CHERRY_PICK_HEAD")
        guard FileManager.default.fileExists(atPath: head.path) else { return .inactive }
        let hash = try? String(contentsOf: head, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        return GitCherryPickStatus(isCherryPicking: true, commitHash: hash?.isEmpty == true ? nil : hash)
    }

    func cherryPick(commits: [String], onto branch: String?, in repository: URL) throws -> String {
        if let branch, !branch.isEmpty { try LibGit2.checkout(branch: branch, at: repository.path) }
        try LibGit2.cherryPick(commits: commits, at: repository.path, verbose: false)
        return "Cherry-pick completed."
    }

    func continueCherryPick(in repository: URL) throws -> String {
        try LibGit2.continueCherryPick(at: repository.path, verbose: false)
        return "Cherry-pick continued."
    }

    func abortCherryPick(in repository: URL) throws -> String {
        try LibGit2.abortCherryPick(at: repository.path, verbose: false)
        return "Cherry-pick aborted."
    }

    func listSubmodules(in repository: URL) -> [GitSubmoduleSummary] {
        (try? LibGit2.submodules(at: repository.path).map {
            GitSubmoduleSummary(path: $0.path, commit: $0.commitHash, url: $0.description ?? "")
        }) ?? []
    }

    func updateSubmodules(in repository: URL) throws {
        try LibGit2.updateSubmodules(at: repository.path, initialize: true, recursive: true, verbose: false)
    }

    func validateCloneDestination(_ destination: URL) throws {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: destination.path, isDirectory: &isDirectory)
        if exists {
            guard isDirectory.boolValue else { throw GitProviderError.backendOperationUnsupported("Destination is not a directory.") }
            guard !FileManager.default.fileExists(atPath: destination.appendingPathComponent(".git").path) else {
                throw GitProviderError.backendOperationUnsupported("Destination is already a git repository.")
            }
            guard (try? FileManager.default.contentsOfDirectory(atPath: destination.path))?.isEmpty == true else {
                throw GitProviderError.backendOperationUnsupported("Destination directory is not empty.")
            }
        }
    }

    func defaultRepositoryName(from remoteURL: String) -> String? {
        let trimmed = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let pathPart: String
        if let schemeRange = trimmed.range(of: "://") {
            pathPart = String(trimmed[schemeRange.upperBound...]).split(separator: "/").dropFirst().joined(separator: "/")
        } else if let colon = trimmed.firstIndex(of: ":") {
            pathPart = String(trimmed[trimmed.index(after: colon)...])
        } else {
            pathPart = trimmed
        }
        let name = pathPart.split(separator: "/").last.map(String.init)?.replacingOccurrences(of: ".git", with: "")
        return name?.isEmpty == false ? name : nil
    }

    func clone(remoteURL: String, destination: URL) throws -> URL {
        try validateCloneDestination(destination)
        try LibGit2.clone(url: remoteURL, to: destination.path)
        return destination
    }

    func clone(
        remoteURL: String,
        destination: URL,
        progress: @escaping @Sendable (GitCloneProgress) -> Void
    ) throws -> URL {
        try cloneUsingLibGit2(
            remoteURL: remoteURL,
            destination: destination,
            progress: progress,
            cancellation: nil
        )
    }

    func clone(
        remoteURL: String,
        destination: URL,
        progress: @escaping @Sendable (GitCloneProgress) -> Void,
        cancellation: GitProcessCancellation?
    ) throws -> URL {
        // 系统 Git 可用时复用 CLI 实现；否则使用 libgit2 的原生传输
        // 回调，同样提供可见进度和中途取消能力。
        if GitProcessRunner.isAvailable {
            return try GitCloneOperation.clone(
                remoteURL: remoteURL,
                destination: destination,
                onProgress: progress,
                cancellation: cancellation
            )
        }

        return try cloneUsingLibGit2(
            remoteURL: remoteURL,
            destination: destination,
            progress: progress,
            cancellation: cancellation
        )
    }

    private func cloneUsingLibGit2(
        remoteURL: String,
        destination: URL,
        progress: @escaping @Sendable (GitCloneProgress) -> Void,
        cancellation: GitProcessCancellation?
    ) throws -> URL {
        try validateCloneDestination(destination)
        progress(.init(phase: .preparing))

        if cancellation?.isCancelled == true {
            throw CancellationError()
        }

        let tracker = LibGit2CloneProgressTracker()
        try LibGit2.clone(
            url: remoteURL,
            to: destination.path,
            onProgress: { value in
                progress(tracker.progress(for: value))
            },
            shouldCancel: {
                cancellation?.isCancelled == true
            }
        )

        if cancellation?.isCancelled == true {
            throw CancellationError()
        }

        progress(.init(phase: .completed, fractionCompleted: 1))
        return destination
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

    func discardAllChanges(in repository: URL) throws {
        // LibGit2Swift 当前没有覆盖 ignored 边界的 clean API，复用 KitGit 的
        // 经过测试的仓库级实现，保证 CLI 与 LibGit2 后端的破坏性语义一致。
        try GitCommitOperation.discardAllChanges(in: repository)
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

    private func validateExpectedHead(_ expectedHead: String, in repository: URL) throws {
        let actual = try LibGit2.getCurrentBranchInfo(at: repository.path)?.latestCommitHash
        guard actual == expectedHead else {
            throw GitProviderError.backendOperationUnsupported("The current HEAD changed before the operation could start.")
        }
    }
}
