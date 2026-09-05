import Foundation
import XCTest
@testable import KitGit

final class GitTagOperationTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-tagop-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        _ = try runGit(["init", "-q"], in: repo)
        _ = try runGit(["config", "user.email", "t@t.com"], in: repo)
        _ = try runGit(["config", "user.name", "t"], in: repo)
        _ = try runGit(["checkout", "-q", "-b", "dev"], in: repo)
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
            throw NSError(domain: "GitTagOperationTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(
            data: output.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
    }

    func testCreatesAndDeletesLightweightAndAnnotatedTags() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        try Data("initial\n".utf8).write(to: repo.appendingPathComponent("README.md"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "initial", in: repo)
        let hash = try GitProcessRunner.run(["rev-parse", "HEAD"], in: repo)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        _ = try GitTagOperation.createLightweight(named: "v1.0.0", at: hash, in: repo)
        _ = try GitTagOperation.createAnnotated(
            named: "release/v1.0.0",
            at: hash,
            message: "First release",
            in: repo
        )

        XCTAssertEqual(
            try GitProcessRunner.run(["rev-parse", "v1.0.0"], in: repo)
                .trimmingCharacters(in: .whitespacesAndNewlines),
            hash
        )
        XCTAssertEqual(
            try GitProcessRunner.run(["for-each-ref", "refs/tags/release/v1.0.0", "--format=%(objecttype)"], in: repo)
                .trimmingCharacters(in: .whitespacesAndNewlines),
            "tag"
        )

        _ = try GitTagOperation.deleteLocal(named: "v1.0.0", in: repo)
        XCTAssertFalse(
            try GitProcessRunner.run(["tag", "--list"], in: repo)
                .split(separator: "\n")
                .contains("v1.0.0")
        )
    }

    func testPushesAndDeletesRemoteTag() throws {
        let repo = try makeRepo()
        let remote = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-tagremote-\(UUID().uuidString).git")
        defer {
            try? FileManager.default.removeItem(at: repo)
            try? FileManager.default.removeItem(at: remote)
        }
        _ = try runGit(["init", "--bare", "-q", remote.path], in: FileManager.default.temporaryDirectory)

        try Data("initial\n".utf8).write(to: repo.appendingPathComponent("README.md"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "initial", in: repo)
        _ = try runGit(["remote", "add", "origin", remote.path], in: repo)
        _ = try runGit(["push", "-q", "origin", "dev"], in: repo)

        _ = try GitTagOperation.createLightweight(named: "v1.0.0", at: "HEAD", in: repo)
        _ = try GitTagOperation.push(named: "v1.0.0", in: repo)
        XCTAssertEqual(
            try runGit(["show-ref", "--verify", "refs/tags/v1.0.0"], in: remote),
            try GitProcessRunner.run(["show-ref", "--verify", "refs/tags/v1.0.0"], in: repo)
        )

        _ = try GitTagOperation.deleteRemote(named: "v1.0.0", in: repo)
        XCTAssertThrowsError(try runGit(["show-ref", "--verify", "refs/tags/v1.0.0"], in: remote))
    }

    func testRejectsEmptyTagNameAndAnnotatedMessage() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertThrowsError(try GitTagOperation.createLightweight(named: "  ", at: "HEAD", in: repo)) { error in
            guard case GitTagOperation.Error.invalidName = error else {
                return XCTFail("expected invalidName, got \(error)")
            }
        }
        XCTAssertThrowsError(
            try GitTagOperation.createAnnotated(named: "v1.0.0", at: "HEAD", message: "  ", in: repo)
        ) { error in
            guard case GitTagOperation.Error.invalidMessage = error else {
                return XCTFail("expected invalidMessage, got \(error)")
            }
        }
    }
}
