import Foundation
import XCTest
@testable import PluginCommitList

final class GitCommitLoaderTests: XCTestCase {
    func testParseOutput() throws {
        let output = """
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\u{1f}aaaaaaa\u{1f}fix: initial commit\u{1f}Alice\u{1f}2026-09-01T10:00:00+08:00
        bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\u{1f}bbbbbbb\u{1f}feat: add feature\u{1f}Bob\u{1f}2026-09-02T08:30:00Z
        """
        let commits = GitCommitLoader.parse(output)
        XCTAssertEqual(commits.count, 2)

        XCTAssertEqual(commits[0].hash, String(repeating: "a", count: 40))
        XCTAssertEqual(commits[0].shortHash, "aaaaaaa")
        XCTAssertEqual(commits[0].message, "fix: initial commit")
        XCTAssertEqual(commits[0].author, "Alice")

        // ISO 8601 时间（含时区）解析。
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 8 * 3600)!, from: commits[0].date)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 9)
        XCTAssertEqual(components.day, 1)
    }

    func testParseSkipsMalformedLines() {
        let output = "goodline\n" // 字段不足，应被跳过
        let commits = GitCommitLoader.parse(output)
        XCTAssertTrue(commits.isEmpty)
    }

    func testParseEmptyOutput() {
        XCTAssertTrue(GitCommitLoader.parse("").isEmpty)
    }

    func testLoadCommitsInRealRepository() throws {
        // 需要系统 git；不可用时跳过集成测试。
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/git") else {
            throw XCTSkip("git not available")
        }

        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitCommitLoaderTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: repo) }
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)

        try run(["git", "-C", repo.path, "init", "-q", "-b", "main"])
        try run(
            [
                "git", "-C", repo.path,
                "-c", "user.name=Test User", "-c", "user.email=test@example.com",
                "commit", "-q", "--allow-empty", "-m", "second commit",
            ],
            env: ["GIT_AUTHOR_DATE": "2026-09-02T09:00:00+08:00", "GIT_COMMITTER_DATE": "2026-09-02T09:00:00+08:00"]
        )
        try run(
            [
                "git", "-C", repo.path,
                "-c", "user.name=Test User", "-c", "user.email=test@example.com",
                "commit", "-q", "--allow-empty", "-m", "first commit",
            ],
            env: ["GIT_AUTHOR_DATE": "2026-09-01T09:00:00+08:00", "GIT_COMMITTER_DATE": "2026-09-01T09:00:00+08:00"]
        )

        let commits = try GitCommitLoader.loadCommits(in: repo, limit: 10)
        XCTAssertEqual(commits.count, 2)
        XCTAssertEqual(commits[0].message, "second commit", "最新提交应在最前")
        XCTAssertEqual(commits[1].message, "first commit")
        XCTAssertEqual(commits[0].author, "Test User")
        XCTAssertEqual(commits[0].hash.count, 40)
        XCTAssertFalse(commits[0].shortHash.isEmpty)
    }

    func testLoadCommitsInNonRepositoryThrows() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NotARepo-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        XCTAssertThrowsError(try GitCommitLoader.loadCommits(in: dir)) { error in
            guard case GitCommitLoaderError.notARepository = error else {
                return XCTFail("expected notARepository, got \(error)")
            }
        }
    }

    // MARK: - Helpers

    @discardableResult
    private func run(_ command: [String], env: [String: String]? = nil) throws -> String {
        // 测试用 git 命令解析为绝对路径，避免相对路径解析到当前目录。
        var resolved = command
        if resolved[0] == "git" { resolved[0] = "/usr/bin/git" }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: resolved[0])
        process.arguments = Array(resolved.dropFirst())
        if let env {
            var environment = ProcessInfo.processInfo.environment
            for (key, value) in env { environment[key] = value }
            process.environment = environment
        }
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            XCTFail("command failed: \(resolved) \(out)")
            throw NSError(domain: "test", code: 1)
        }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
