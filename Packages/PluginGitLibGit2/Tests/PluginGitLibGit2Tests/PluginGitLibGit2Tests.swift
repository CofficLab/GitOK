import Foundation
import KitGit
import Testing
@testable import PluginGitLibGit2

@Suite("PluginGitLibGit2")
struct PluginGitLibGit2Tests {
    @Test("LibGit2 插件作为内置必需后端并使用固定版本")
    @MainActor
    func metadata() {
        let plugin = GitLibGit2Plugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-libgit2")
        #expect(plugin.metadata.policy == .required)
    }

    @Test("cancellable list reads stop before entering LibGit2Swift")
    func cancellableListReadHonorsCancellation() {
        let cancellation = GitProcessCancellation()
        cancellation.cancel()
        let repository = URL(fileURLWithPath: "/missing/project")
        let backend = GitLibGit2Backend()

        #expect(throws: CancellationError.self) {
            try backend.loadCommits(
                in: repository,
                limit: 50,
                offset: 0,
                cancellation: cancellation
            )
        }
    }

    @Test("cancellable status reads stop before entering LibGit2Swift")
    func cancellableStatusReadHonorsCancellation() {
        let cancellation = GitProcessCancellation()
        cancellation.cancel()
        let repository = URL(fileURLWithPath: "/missing/project")
        let backend = GitLibGit2Backend()

        #expect(throws: CancellationError.self) {
            try backend.loadStatus(in: repository, cancellation: cancellation)
        }
    }

    @Test("LibGit2 backend discards staged new files")
    func discardStagedNewFile() throws {
        let repository = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-libgit2-discard-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: repository) }
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)

        _ = try GitProcessRunner.run(["init", "-q"], in: repository)
        _ = try GitProcessRunner.run(["config", "user.email", "test@example.com"], in: repository)
        _ = try GitProcessRunner.run(["config", "user.name", "GitOK Test"], in: repository)
        _ = try GitProcessRunner.run(["checkout", "-q", "-b", "dev"], in: repository)

        try Data("initial\n".utf8).write(to: repository.appendingPathComponent("initial.txt"))
        try GitCommitOperation.addAll(in: repository)
        try GitCommitOperation.commit(message: "initial", in: repository)

        let newFile = repository.appendingPathComponent("new.txt")
        try Data("new\n".utf8).write(to: newFile)
        try GitCommitOperation.stageFiles(["new.txt"], in: repository)

        try GitLibGit2Backend().discardFiles(["new.txt"], in: repository)

        #expect(!FileManager.default.fileExists(atPath: newFile.path))
        #expect(try GitStatusLoader.loadStatus(in: repository).isClean)
    }

    @Test("defaultRepositoryName parses https / scp / bare paths")
    func defaultRepositoryNameParsing() {
        let backend = GitLibGit2Backend()
        #expect(backend.defaultRepositoryName(from: "https://github.com/owner/repo.git") == "repo")
        #expect(backend.defaultRepositoryName(from: "https://github.com/owner/repo") == "repo")
        #expect(backend.defaultRepositoryName(from: "git@github.com:owner/repo.git") == "repo")
        #expect(backend.defaultRepositoryName(from: "ssh://git@github.com/owner/repo.git") == "repo")
        #expect(backend.defaultRepositoryName(from: "  ") == nil)
        #expect(backend.defaultRepositoryName(from: "") == nil)
    }

    @Test("webLink converts scp and https remote URLs")
    func webLinkParsing() {
        let backend = GitLibGit2Backend()
        #expect(backend.webLink(for: "git@github.com:owner/repo.git")?.absoluteString == "https://github.com/owner/repo")
        #expect(backend.webLink(for: "https://github.com/owner/repo.git")?.absoluteString == "https://github.com/owner/repo")
        #expect(backend.webLink(for: "not-a-url") == nil)
    }

    @Test("cherryPickStatus inactive for clean repository")
    func cherryPickStatusInactive() throws {
        let repository = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-libgit2-cp-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: repository) }
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        _ = try GitProcessRunner.run(["init", "-q"], in: repository)
        #expect(GitLibGit2Backend().cherryPickStatus(in: repository).isCherryPicking == false)
    }

    /// 构造一次内容冲突的合并，返回仓库地址。
    private func makeConflictedRepository() throws -> URL {
        let repository = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-libgit2-conflict-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)

        _ = try GitProcessRunner.run(["init", "-q", "-b", "dev"], in: repository)
        _ = try GitProcessRunner.run(["config", "user.email", "test@example.com"], in: repository)
        _ = try GitProcessRunner.run(["config", "user.name", "GitOK Test"], in: repository)
        try Data("base\n".utf8).write(to: repository.appendingPathComponent("shared.txt"))
        _ = try GitProcessRunner.run(["add", "."], in: repository)
        _ = try GitProcessRunner.run(["commit", "-q", "-m", "base"], in: repository)

        _ = try GitProcessRunner.run(["checkout", "-q", "-b", "feature"], in: repository)
        try Data("theirs\n".utf8).write(to: repository.appendingPathComponent("shared.txt"))
        _ = try GitProcessRunner.run(["commit", "-q", "-am", "theirs"], in: repository)

        _ = try GitProcessRunner.run(["checkout", "-q", "dev"], in: repository)
        try Data("ours\n".utf8).write(to: repository.appendingPathComponent("shared.txt"))
        _ = try GitProcessRunner.run(["commit", "-q", "-am", "ours"], in: repository)

        _ = try? GitProcessRunner.run(["merge", "feature"], in: repository)
        return repository
    }

    @Test("conflict entries read the exact unmerged stages")
    func conflictEntriesReadExactStages() throws {
        let repository = try makeConflictedRepository()
        defer { try? FileManager.default.removeItem(at: repository) }

        let entries = GitLibGit2Backend().conflictEntries(in: repository)
        #expect(entries == [GitConflictEntry(path: "shared.txt", kind: .content)])
    }

    @Test("unstage collapses unmerged index entries")
    func unstageCollapsesUnmergedEntries() throws {
        let repository = try makeConflictedRepository()
        defer { try? FileManager.default.removeItem(at: repository) }

        let backend = GitLibGit2Backend()
        #expect(!backend.conflictFiles(in: repository).isEmpty)
        try backend.unstageFiles(["shared.txt"], in: repository)

        #expect(backend.conflictFiles(in: repository).isEmpty)
        #expect(backend.conflictEntries(in: repository).isEmpty)
        let cachedDiff = try GitProcessRunner.run(["diff", "--cached", "--name-only"], in: repository)
        #expect(cachedDiff.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
