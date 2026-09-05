import Foundation
import XCTest
@testable import KitGit

final class GitMergeOperationTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-mergeop-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        _ = try runGit(["init", "-q"], in: repo)
        _ = try runGit(["config", "user.email", "t@t.com"], in: repo)
        _ = try runGit(["config", "user.name", "t"], in: repo)
        _ = try runGit(["checkout", "-q", "-b", "dev"], in: repo)
        try Data("base\n".utf8).write(to: repo.appendingPathComponent("shared.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "initial", in: repo)
        return repo
    }

    private func runGit(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(
                data: error.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? "git failed"
            throw NSError(domain: "GitMergeOperationTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(
            data: output.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
    }

    private func createConflict(in repo: URL) throws {
        _ = try runGit(["checkout", "-q", "-b", "feature"], in: repo)
        try Data("theirs\n".utf8).write(to: repo.appendingPathComponent("shared.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "feature change", in: repo)

        _ = try runGit(["checkout", "-q", "dev"], in: repo)
        try Data("ours\n".utf8).write(to: repo.appendingPathComponent("shared.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "dev change", in: repo)
    }

    func testReadsConflictVersionsChoosesTheirsAndContinuesMerge() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        try createConflict(in: repo)

        XCTAssertThrowsError(
            try GitMergeOperation.mergeBranches(repository: repo, sourceBranch: "feature", targetBranch: "dev")
        ) { error in
            guard case GitMergeError.conflict(_, let files) = error else {
                return XCTFail("expected conflict, got \(error)")
            }
            XCTAssertEqual(files, ["shared.txt"])
        }
        XCTAssertTrue(GitMergeOperation.isMerging(in: repo))
        XCTAssertEqual(GitMergeOperation.conflictFiles(in: repo), ["shared.txt"])
        XCTAssertEqual(
            try GitMergeOperation.mergeFileContent(path: "shared.txt", version: .base, in: repo),
            "base\n"
        )
        XCTAssertEqual(
            try GitMergeOperation.mergeFileContent(path: "shared.txt", version: .ours, in: repo),
            "ours\n"
        )
        XCTAssertEqual(
            try GitMergeOperation.mergeFileContent(path: "shared.txt", version: .theirs, in: repo),
            "theirs\n"
        )
        XCTAssertTrue(try GitMergeOperation.mergeFileDiff(path: "shared.txt", in: repo).contains("diff --cc shared.txt"))

        try GitMergeOperation.checkoutMergeFileVersion(path: "shared.txt", version: .theirs, in: repo)
        XCTAssertEqual(
            try String(contentsOf: repo.appendingPathComponent("shared.txt"), encoding: .utf8),
            "theirs\n"
        )
        XCTAssertTrue(GitMergeOperation.conflictFiles(in: repo).isEmpty)

        _ = try GitMergeOperation.continueMerge(in: repo)
        XCTAssertFalse(GitMergeOperation.isMerging(in: repo))
        XCTAssertTrue(try GitStatusLoader.loadStatus(in: repo).isClean)
    }

    func testAbortMergeRestoresPreMergeWorktree() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        try createConflict(in: repo)

        XCTAssertThrowsError(
            try GitMergeOperation.mergeBranches(repository: repo, sourceBranch: "feature", targetBranch: "dev")
        )
        _ = try GitMergeOperation.abortMerge(in: repo)

        XCTAssertFalse(GitMergeOperation.isMerging(in: repo))
        XCTAssertTrue(GitMergeOperation.conflictFiles(in: repo).isEmpty)
        XCTAssertEqual(
            try String(contentsOf: repo.appendingPathComponent("shared.txt"), encoding: .utf8),
            "ours\n"
        )
        XCTAssertTrue(try GitStatusLoader.loadStatus(in: repo).isClean)
    }
}
