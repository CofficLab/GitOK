import Foundation
import GitCoreKit
import XCTest

final class GitRepositoryCLITests: XCTestCase {
    func testStashLifecycle() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        try repo.write("notes.txt", content: "one\n")

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.stashSave(message: "save notes")

        let stashes = try client.stashList()
        XCTAssertEqual(stashes.count, 1)
        XCTAssertEqual(stashes[0].message, "save notes")
        XCTAssertEqual(try repo.read("notes.txt"), nil)

        try client.stashApply(index: 0)
        XCTAssertEqual(try repo.read("notes.txt"), "one\n")
        XCTAssertEqual(try client.stashList().count, 1)

        try client.stashDrop(index: 0)
        XCTAssertTrue(try client.stashList().isEmpty)
    }

    func testStashSaveWithoutWorkingTreeChangesLeavesListEmpty() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        try client.stashSave(message: "nothing to save")
        XCTAssertTrue(try client.stashList().isEmpty)
    }

    func testStashSaveCapturesUntrackedFiles() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        try repo.write("draft.md", content: "hello\n")

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.stashSave(message: "untracked only")

        XCTAssertNil(try repo.read("draft.md"))
        XCTAssertEqual(
            try client.stashList(),
            [GitStashEntry(index: 0, message: "untracked only")]
        )

        try client.stashPop(index: 0)
        XCTAssertEqual(try repo.read("draft.md"), "hello\n")
        XCTAssertTrue(try client.stashList().isEmpty)
    }

    func testStashPopConflictKeepsEntryAndMarksConflict() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        try repo.write("shared.txt", content: "stash change\n")
        try client.stashSave(message: "pop conflict candidate")

        try repo.write("shared.txt", content: "head change\n")
        try repo.run(["commit", "-am", "head change"])

        XCTAssertThrowsError(try client.stashPop(index: 0))
        XCTAssertEqual(try client.stashList(), [GitStashEntry(index: 0, message: "pop conflict candidate")])
        XCTAssertEqual(
            try client.statusEntries(),
            [GitStatusEntry(path: "shared.txt", indexStatus: "U", workTreeStatus: "U")]
        )
    }

    func testStashApplyConflictKeepsEntryAndMarksConflict() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        try repo.write("shared.txt", content: "stash change\n")
        try client.stashSave(message: "conflict candidate")

        try repo.write("shared.txt", content: "head change\n")
        try repo.run(["commit", "-am", "head change"])

        XCTAssertThrowsError(try client.stashApply(index: 0))
        XCTAssertEqual(try client.stashList(), [GitStashEntry(index: 0, message: "conflict candidate")])
        XCTAssertEqual(try client.statusEntries(), [GitStatusEntry(path: "shared.txt", indexStatus: "U", workTreeStatus: "U")])
    }

    func testStashCommandsThrowForMissingIndex() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.stashApply(index: 99))
        XCTAssertThrowsError(try client.stashPop(index: 99))
        XCTAssertThrowsError(try client.stashDrop(index: 99))
    }

    func testMergeConflictLifecycle() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        try repo.run(["checkout", "-b", "feature"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "master\n")
        try repo.run(["commit", "-am", "master change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try repo.run(["merge", "feature"])) { _ in }
        XCTAssertTrue(try client.isMerging())
        XCTAssertEqual(try client.getCurrentMergeBranchName(), "feature")
        XCTAssertEqual(try client.getMergeConflictFiles(), ["shared.txt"])

        try repo.write("shared.txt", content: "resolved\n")
        try client.addFiles(["shared.txt"])

        try client.continueMerge()
        XCTAssertFalse(try client.isMerging())
    }

    func testGetCurrentMergeBranchNameReturnsNilOutsideMerge() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertFalse(try client.isMerging())
        XCTAssertNil(try client.getCurrentMergeBranchName())
    }

    func testContinueMergeThrowsUntilFilesAreStaged() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        try repo.run(["checkout", "-b", "feature"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "master\n")
        try repo.run(["commit", "-am", "master change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertThrowsError(try repo.run(["merge", "feature"])) { _ in }

        try repo.write("shared.txt", content: "resolved but unstaged\n")

        XCTAssertThrowsError(try client.continueMerge())
        XCTAssertTrue(try client.isMerging())
    }

    func testAbortMergeRestoresRepositoryState() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        try repo.run(["checkout", "-b", "feature"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "master\n")
        try repo.run(["commit", "-am", "master change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertThrowsError(try repo.run(["merge", "feature"])) { _ in }
        XCTAssertTrue(try client.isMerging())

        try client.abortMerge()

        XCTAssertFalse(try client.isMerging())
        XCTAssertEqual(try client.getMergeConflictFiles(), [])
        XCTAssertEqual(try repo.read("shared.txt"), "master\n")
    }

    func testAbortMergeOutsideMergeThrows() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertThrowsError(try client.abortMerge())
    }

    func testCloneRepositoryIntoNewDirectory() throws {
        let remote = try TestGitRepository()
        try remote.write("README.md", content: "hello\n")
        try remote.run(["add", "."])
        try remote.run(["commit", "-m", "initial"])

        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let destinationURL = destinationRoot.appendingPathComponent("cloned-repo", isDirectory: true)
        try GitRepositoryCLI.clone(remoteURL: remote.url.path, destinationURL: destinationURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.appendingPathComponent(".git").path))
        XCTAssertEqual(try String(contentsOf: destinationURL.appendingPathComponent("README.md"), encoding: .utf8), "hello\n")
    }

    func testCloneFailureRemovesNewlyCreatedDestinationDirectory() throws {
        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let destinationURL = destinationRoot.appendingPathComponent("missing-repo", isDirectory: true)

        XCTAssertThrowsError(try GitRepositoryCLI.clone(remoteURL: "/tmp/definitely-missing-repo", destinationURL: destinationURL))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destinationURL.path))
    }

    func testCloneFailureKeepsPreexistingDestinationDirectory() throws {
        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let destinationURL = destinationRoot.appendingPathComponent("existing-empty-dir", isDirectory: true)
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)

        XCTAssertThrowsError(try GitRepositoryCLI.clone(remoteURL: "/tmp/definitely-missing-repo", destinationURL: destinationURL))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path))
    }
}

private final class TestGitRepository {
    let url: URL

    init() throws {
        let base = FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory

        try run(["init", "-b", "master"])
        try run(["config", "user.name", "Test User"])
        try run(["config", "user.email", "test@example.com"])
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    func write(_ relativePath: String, content: String) throws {
        let fileURL = url.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.data(using: .utf8)?.write(to: fileURL)
    }

    func read(_ relativePath: String) throws -> String? {
        let fileURL = url.appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    @discardableResult
    func run(_ arguments: [String], allowNonZeroExit: Bool = false) throws -> String {
        let process = Process()
        process.currentDirectoryURL = url
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard allowNonZeroExit || process.terminationStatus == 0 else {
            let message = stderr.isEmpty ? stdout : stderr
            throw NSError(domain: "TestGitRepository", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }

        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
