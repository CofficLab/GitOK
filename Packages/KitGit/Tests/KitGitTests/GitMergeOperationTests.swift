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

    func testCheckoutMergeFileVersionBaseReplacesConflictedFileAndStagesIt() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        try createConflict(in: repo)

        XCTAssertThrowsError(
            try GitMergeOperation.mergeBranches(repository: repo, sourceBranch: "feature", targetBranch: "dev")
        )

        // “Use Base” 必须覆盖工作区里已存在的冲突文件，而不是因文件存在而失败。
        try GitMergeOperation.checkoutMergeFileVersion(path: "shared.txt", version: .base, in: repo)
        XCTAssertEqual(
            try String(contentsOf: repo.appendingPathComponent("shared.txt"), encoding: .utf8),
            "base\n"
        )
        XCTAssertTrue(GitMergeOperation.conflictFiles(in: repo).isEmpty)
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

    // MARK: - 冲突条目形状

    func testConflictEntryKindsFollowIndexStages() {
        let oid = String(repeating: "a", count: 40)
        let listing = [
            "100644 \(oid) 1\tdeleted.txt",
            "100644 \(oid) 2\taAddedByUs.txt",
            "100644 \(oid) 3\taAddedByThem.txt",
            "100644 \(oid) 1\tdeletedByUs.txt",
            "100644 \(oid) 3\tdeletedByUs.txt",
            "100644 \(oid) 1\tdeletedByThem.txt",
            "100644 \(oid) 2\tdeletedByThem.txt",
            "100644 \(oid) 2\tbothModified.txt",
            "100644 \(oid) 3\tbothModified.txt",
            "100644 \(oid) 1\tallThree.txt",
            "100644 \(oid) 2\tallThree.txt",
            "100644 \(oid) 3\tallThree.txt",
        ].joined(separator: "\0") + "\0"

        let entries = GitMergeOperation.conflictEntries(fromUnmergedListing: listing)
        let kinds = Dictionary(uniqueKeysWithValues: entries.map { ($0.path, $0.kind) })

        XCTAssertEqual(kinds["deleted.txt"], .bothDeleted)
        XCTAssertEqual(kinds["aAddedByUs.txt"], .oneSided)
        XCTAssertEqual(kinds["aAddedByThem.txt"], .oneSided)
        XCTAssertEqual(kinds["deletedByUs.txt"], .deleteModify)
        XCTAssertEqual(kinds["deletedByThem.txt"], .deleteModify)
        XCTAssertEqual(kinds["bothModified.txt"], .content)
        XCTAssertEqual(kinds["allThree.txt"], .content)
        XCTAssertEqual(entries.map(\.path), kinds.keys.sorted())
    }

    func testModifyDeleteConflictIsNotClassifiedAsAutoResolvable() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        _ = try runGit(["checkout", "-q", "-b", "feature"], in: repo)
        try FileManager.default.removeItem(at: repo.appendingPathComponent("shared.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "feature deletes", in: repo)

        _ = try runGit(["checkout", "-q", "dev"], in: repo)
        try Data("ours\n".utf8).write(to: repo.appendingPathComponent("shared.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "dev modifies", in: repo)

        XCTAssertThrowsError(
            try GitMergeOperation.mergeBranches(repository: repo, sourceBranch: "feature", targetBranch: "dev")
        ) { error in
            guard case GitMergeError.conflict(_, let files) = error else {
                return XCTFail("expected conflict, got \(error)")
            }
            XCTAssertEqual(files, ["shared.txt"])
        }

        XCTAssertEqual(
            GitMergeOperation.conflictEntries(in: repo),
            [GitConflictEntry(path: "shared.txt", kind: .deleteModify)]
        )
    }
}
