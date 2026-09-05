import Foundation
import XCTest
@testable import KitGit

final class GitBranchOperationTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-branchop-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        _ = try runGit(["init", "-q"], in: repo)
        _ = try runGit(["config", "user.email", "t@t.com"], in: repo)
        _ = try runGit(["config", "user.name", "t"], in: repo)
        _ = try runGit(["checkout", "-q", "-b", "dev"], in: repo)
        try Data("initial\n".utf8).write(to: repo.appendingPathComponent("README.md"))
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
            throw NSError(domain: "GitBranchOperationTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(
            data: output.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
    }

    func testRenamesAndConfiguresUpstream() throws {
        let repo = try makeRepo()
        let remote = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-branchremote-\(UUID().uuidString).git")
        defer {
            try? FileManager.default.removeItem(at: repo)
            try? FileManager.default.removeItem(at: remote)
        }
        _ = try runGit(["init", "--bare", "-q", remote.path], in: FileManager.default.temporaryDirectory)
        _ = try runGit(["remote", "add", "origin", remote.path], in: repo)
        _ = try runGit(["push", "-q", "origin", "dev"], in: repo)

        try GitBranchOperation.renameBranch(from: "dev", to: "main", in: repo)
        XCTAssertEqual(
            GitRefReader.currentBranch(in: repo),
            "main"
        )

        try GitBranchOperation.setUpstream(
            localBranch: "main",
            upstreamBranch: "origin/dev",
            in: repo
        )
        XCTAssertEqual(
            try GitProcessRunner.run(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "main@{upstream}"], in: repo)
                .trimmingCharacters(in: .whitespacesAndNewlines),
            "origin/dev"
        )

        try GitBranchOperation.unsetUpstream(localBranch: "main", in: repo)
        XCTAssertThrowsError(try GitProcessRunner.run(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "main@{upstream}"], in: repo))
    }

    func testPublishesAndDeletesRemoteBranch() throws {
        let repo = try makeRepo()
        let remote = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-branchremote-\(UUID().uuidString).git")
        defer {
            try? FileManager.default.removeItem(at: repo)
            try? FileManager.default.removeItem(at: remote)
        }
        _ = try runGit(["init", "--bare", "-q", remote.path], in: FileManager.default.temporaryDirectory)
        _ = try runGit(["remote", "add", "origin", remote.path], in: repo)
        _ = try runGit(["branch", "feature/publish"], in: repo)

        try GitBranchOperation.publishBranch(
            localBranch: "feature/publish",
            in: repo
        )
        let remoteBranchHash = try runGit(["show-ref", "--verify", "refs/heads/feature/publish"], in: remote)
            .split(separator: " ")
            .first
            .map(String.init)
        let localBranchHash = try GitProcessRunner.run(["rev-parse", "feature/publish"], in: repo)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(
            remoteBranchHash,
            localBranchHash
        )

        try GitBranchOperation.deleteRemoteBranch(
            named: "origin/feature/publish",
            in: repo
        )
        XCTAssertThrowsError(try runGit(["show-ref", "--verify", "refs/heads/feature/publish"], in: remote))
    }

    func testRejectsRemoteHeadDeletion() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertThrowsError(
            try GitBranchOperation.deleteRemoteBranch(named: "origin/HEAD", in: repo)
        ) { error in
            guard case GitBranchOperation.Error.cannotDeleteRemoteHead = error else {
                return XCTFail("expected cannotDeleteRemoteHead, got \(error)")
            }
        }
    }
}
