import Foundation
import XCTest
@testable import KitGit

final class GitBranchCompareTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-branchcompare-\(UUID().uuidString)")
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
            throw NSError(domain: "GitBranchCompareTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(
            data: output.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
    }

    func testCompareReturnsAheadBehindCommitsAndFiles() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        try Data("base\n".utf8).write(to: repo.appendingPathComponent("shared.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "initial", in: repo)

        _ = try runGit(["checkout", "-q", "-b", "feature/compare"], in: repo)
        try Data("feature\n".utf8).write(to: repo.appendingPathComponent("shared.txt"))
        try Data("added\n".utf8).write(to: repo.appendingPathComponent("added.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "feature change", in: repo)

        _ = try runGit(["checkout", "-q", "dev"], in: repo)
        try Data("base\n".utf8).write(to: repo.appendingPathComponent("base-only.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "base change", in: repo)

        let compare = try GitBranchOperation.compareBranches(
            base: "dev",
            head: "feature/compare",
            in: repo
        )

        XCTAssertEqual(compare.base, "dev")
        XCTAssertEqual(compare.head, "feature/compare")
        XCTAssertEqual(compare.ahead, 1)
        XCTAssertEqual(compare.behind, 1)
        XCTAssertEqual(compare.commits.map(\.subject), ["feature change"])
        XCTAssertEqual(
            compare.files,
            [
                GitBranchCompareFile(status: "A", path: "added.txt"),
                GitBranchCompareFile(status: "M", path: "shared.txt")
            ]
        )
    }

    func testCompareRejectsMissingOrIdenticalBranches() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        try Data("initial\n".utf8).write(to: repo.appendingPathComponent("README.md"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "initial", in: repo)

        XCTAssertThrowsError(
            try GitBranchOperation.compareBranches(base: "missing", head: "dev", in: repo)
        )
        XCTAssertThrowsError(
            try GitBranchOperation.compareBranches(base: "dev", head: "dev", in: repo)
        ) { error in
            guard case GitBranchCompareOperation.Error.invalidBranch = error else {
                return XCTFail("expected invalidBranch, got \(error)")
            }
        }
    }
}
