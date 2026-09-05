import Foundation
import XCTest
@testable import KitGit

/// `GitCommitOperation` 提交工作流的集成测试（真实 git CLI + 临时仓库）。
final class GitCommitOperationTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-commitop-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        func run(_ args: [String]) throws {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            p.arguments = args
            p.currentDirectoryURL = repo
            p.standardOutput = Pipe()
            p.standardError = Pipe()
            try p.run()
            p.waitUntilExit()
        }
        try run(["init", "-q"])
        try run(["config", "user.email", "t@t.com"])
        try run(["config", "user.name", "t"])
        try run(["checkout", "-q", "-b", "dev"])
        return repo
    }

    func testAddAllAndCommitWithMultiParagraphMessage() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        try Data("hello\n".utf8).write(to: repo.appendingPathComponent("a.txt"))

        XCTAssertFalse(try GitCommitOperation.hasStagedChanges(in: repo))
        try GitCommitOperation.addAll(in: repo)
        XCTAssertTrue(try GitCommitOperation.hasStagedChanges(in: repo))

        let message = "✨ Chore: Minor adjustments\n\nCo-authored-by: Jane <jane@t.com>"
        try GitCommitOperation.commit(message: message, in: repo)

        // 提交成功后工作区应干净，且 message 含 Co-authored-by 段。
        let status = try GitStatusLoader.loadStatus(in: repo)
        XCTAssertTrue(status.isClean)

        let output = try GitProcessRunner.run(["log", "-1", "--format=%B"], in: repo)
        XCTAssertTrue(output.contains("Minor adjustments"))
        XCTAssertTrue(output.contains("Co-authored-by: Jane <jane@t.com>"))
    }

    func testStageFilesStagesOnlyRequestedFilesAndEmptyInputIsNoOp() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        try Data("a\n".utf8).write(to: repo.appendingPathComponent("a.txt"))
        try Data("b\n".utf8).write(to: repo.appendingPathComponent("b.txt"))

        try GitCommitOperation.stageFiles([], in: repo)
        var entries = try GitStatusLoader.loadEntries(in: repo)
        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries.allSatisfy(\.isUntracked))

        try GitCommitOperation.stageFiles(["a.txt"], in: repo)
        entries = try GitStatusLoader.loadEntries(in: repo)

        let staged = try XCTUnwrap(entries.first(where: { $0.path == "a.txt" }))
        XCTAssertEqual(staged.stagedStatus, "A")
        XCTAssertEqual(staged.worktreeStatus, " ")

        let untouched = try XCTUnwrap(entries.first(where: { $0.path == "b.txt" }))
        XCTAssertTrue(untouched.isUntracked)
    }

    func testCommitWithNothingToCommitThrows() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        try Data("hello\n".utf8).write(to: repo.appendingPathComponent("a.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "first", in: repo)

        // 再次提交（无改动）应抛 nothingToCommit。
        XCTAssertThrowsError(try GitCommitOperation.commit(message: "second", in: repo)) { error in
            guard case GitCommitOperation.Error.nothingToCommit = error else {
                return XCTFail("expected nothingToCommit, got \(error)")
            }
        }
    }
}
