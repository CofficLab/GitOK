import Foundation
import LibGit2Swift
import MagicKit

extension Project {
    // Convenience method to checkout with MagicKit.GitBranch
    func checkout(magicKitBranch: MagicKit.GitBranch) throws {
        let branchData = MagicKitBranchData(
            id: magicKitBranch.id,
            name: magicKitBranch.name,
            isCurrent: magicKitBranch.isCurrent,
            upstream: magicKitBranch.upstream,
            latestCommitHash: magicKitBranch.latestCommitHash,
            latestCommitMessage: magicKitBranch.latestCommitMessage
        )
        try checkout(magicKitBranchData: branchData)
    }

    func getMagicKitCommitsWithPagination(_ page: Int, limit: Int) throws -> [MagicKit.GitCommit] {
        let lgCommits = try getCommitsWithPagination(page, limit: limit)
        return lgCommits.map { commit in
            MagicKit.GitCommit(
                id: commit.id,
                hash: commit.hash,
                author: commit.author,
                email: commit.email,
                date: commit.date,
                message: commit.message,
                body: commit.body,
                refs: commit.refs,
                tags: commit.tags
            )
        }
    }

    func getMagicKitBranches() throws -> [MagicKit.GitBranch] {
        let lgBranches = try getBranches()
        return lgBranches.map { branch in
            MagicKit.GitBranch(
                id: branch.id,
                name: branch.name,
                isCurrent: branch.isCurrent,
                upstream: branch.upstream,
                latestCommitHash: branch.latestCommitHash,
                latestCommitMessage: branch.latestCommitMessage
            )
        }
    }

    func getMagicKitCurrentBranch() throws -> MagicKit.GitBranch? {
        guard let lgBranch = try getCurrentBranch() else { return nil }
        return MagicKit.GitBranch(
            id: lgBranch.id,
            name: lgBranch.name,
            isCurrent: lgBranch.isCurrent,
            upstream: lgBranch.upstream,
            latestCommitHash: lgBranch.latestCommitHash,
            latestCommitMessage: lgBranch.latestCommitMessage
        )
    }

    func getMagicKitRemotes() throws -> [MagicKit.GitRemote] {
        let lgRemotes = try remoteList()
        return lgRemotes.map { remote in
            MagicKit.GitRemote(
                id: remote.id,
                name: remote.name,
                url: remote.url,
                fetchURL: remote.fetchURL,
                pushURL: remote.pushURL,
                isDefault: remote.isDefault
            )
        }
    }

    func fileList(atCommit: String) async throws -> [MagicKit.GitDiffFile] {
        let lgFiles = try await changedFilesDetail(in: atCommit)
        return lgFiles.map { file in
            MagicKit.GitDiffFile(
                id: file.id,
                file: file.file,
                changeType: file.changeType,
                diff: file.diff
            )
        }
    }

    func getMagicKitUntrackedFiles() async throws -> [MagicKit.GitDiffFile] {
        let lgFiles = try await untrackedFiles()
        return lgFiles.map { file in
            MagicKit.GitDiffFile(
                id: file.id,
                file: file.file,
                changeType: file.changeType,
                diff: file.diff
            )
        }
    }
}
