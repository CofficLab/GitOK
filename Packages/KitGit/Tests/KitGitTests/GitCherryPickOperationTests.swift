import Foundation
import XCTest
@testable import KitGit

final class GitCherryPickOperationTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-cherrypick-\(UUID().uuidString)")
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
            throw NSError(domain: "GitCherryPickOperationTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(
            data: output.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
    }

    private func currentHash(in repo: URL) throws -> String {
        try GitProcessRunner.run(["rev-parse", "HEAD"], in: repo)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createFeature(in repo: URL) throws -> [String] {
        _ = try runGit(["checkout", "-q", "-b", "feature"], in: repo)
        try Data("one\n".utf8).write(to: repo.appendingPathComponent("one.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "feature one", in: repo)
        let first = try currentHash(in: repo)

        try Data("two\n".utf8).write(to: repo.appendingPathComponent("two.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "feature two", in: repo)
        let second = try currentHash(in: repo)
        return [first, second]
    }

    private func createConflict(in repo: URL) throws -> String {
        _ = try runGit(["checkout", "-q", "-b", "feature"], in: repo)
        try Data("theirs\n".utf8).write(to: repo.appendingPathComponent("shared.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "feature change", in: repo)
        let featureHash = try currentHash(in: repo)

        _ = try runGit(["checkout", "-q", "dev"], in: repo)
        try Data("ours\n".utf8).write(to: repo.appendingPathComponent("shared.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "dev change", in: repo)
        return featureHash
    }

    func testCherryPicksMultipleCommitsInOrder() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        let hashes = try createFeature(in: repo)
        _ = try runGit(["checkout", "-q", "dev"], in: repo)

        _ = try GitCherryPickOperation.cherryPick(commits: hashes, in: repo)

        XCTAssertEqual(GitCherryPickOperation.status(in: repo), .inactive)
        XCTAssertEqual(try String(contentsOf: repo.appendingPathComponent("one.txt")), "one\n")
        XCTAssertEqual(try String(contentsOf: repo.appendingPathComponent("two.txt")), "two\n")
        XCTAssertEqual(
            try GitProcessRunner.run(["log", "-2", "--format=%s"], in: repo),
            "feature two\nfeature one\n"
        )
    }

    func testContinuesAConflictAfterChoosingTheirs() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        let featureHash = try createConflict(in: repo)

        XCTAssertThrowsError(
            try GitCherryPickOperation.cherryPick(commits: [featureHash], onto: "dev", in: repo)
        ) { error in
            guard case GitCherryPickError.conflict(_, let files) = error else {
                return XCTFail("expected cherry-pick conflict, got \(error)")
            }
            XCTAssertEqual(files, ["shared.txt"])
        }
        XCTAssertTrue(GitCherryPickOperation.status(in: repo).isCherryPicking)
        XCTAssertEqual(
            try GitMergeOperation.mergeFileContent(path: "shared.txt", version: .theirs, in: repo),
            "theirs\n"
        )

        try GitMergeOperation.checkoutMergeFileVersion(path: "shared.txt", version: .theirs, in: repo)
        _ = try GitCherryPickOperation.continueCherryPick(in: repo)

        XCTAssertEqual(GitCherryPickOperation.status(in: repo), .inactive)
        XCTAssertEqual(try String(contentsOf: repo.appendingPathComponent("shared.txt")), "theirs\n")
        XCTAssertTrue(try GitStatusLoader.loadStatus(in: repo).isClean)
    }

    func testAbortRestoresPreCherryPickWorktree() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        let featureHash = try createConflict(in: repo)

        XCTAssertThrowsError(
            try GitCherryPickOperation.cherryPick(commits: [featureHash], onto: "dev", in: repo)
        )
        _ = try GitCherryPickOperation.abortCherryPick(in: repo)

        XCTAssertEqual(GitCherryPickOperation.status(in: repo), .inactive)
        XCTAssertEqual(try String(contentsOf: repo.appendingPathComponent("shared.txt")), "ours\n")
        XCTAssertTrue(try GitStatusLoader.loadStatus(in: repo).isClean)
    }
}
