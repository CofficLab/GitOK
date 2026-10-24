import Foundation
import XCTest
@testable import KitGit

/// 覆盖 `GitTagReader` 的本地 tag 详情读取。
///
/// commit 列表里的 tag 胶囊只显示前几个字符，展开视图依赖这份详情展示
/// 完整的 tag 名、类型、指向的提交与创建信息，所以这里用真实仓库验证
/// 轻量 tag / 附注 tag / 不存在的 tag 三条路径。
final class GitTagDetailTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-tagdetail-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        _ = try runGit(["init", "-q"], in: repo)
        _ = try runGit(["config", "user.email", "tagger@example.com"], in: repo)
        _ = try runGit(["config", "user.name", "Tag Owner"], in: repo)
        return repo
    }

    @discardableResult
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
            throw NSError(domain: "GitTagDetailTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(
            data: output.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
    }

    /// 建一个只有一条提交的仓库，返回该提交的完整哈希。
    private func makeCommit(in repo: URL, subject: String = "Initial commit subject") throws -> String {
        try Data("initial\n".utf8).write(to: repo.appendingPathComponent("README.md"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: subject, in: repo)
        return try runGit(["rev-parse", "HEAD"], in: repo)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func testReadsLightweightTagDetail() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        let hash = try makeCommit(in: repo)
        _ = try GitTagOperation.createLightweight(named: "v1.0.0", at: hash, in: repo)

        let detail = try XCTUnwrap(GitTagReader.detail(named: "v1.0.0", in: repo))

        XCTAssertEqual(detail.name, "v1.0.0")
        XCTAssertEqual(detail.kind, .lightweight)
        XCTAssertEqual(detail.targetHash, hash)
        XCTAssertEqual(detail.targetSubject, "Initial commit subject")
        XCTAssertNil(detail.message, "A lightweight tag has no message")
        XCTAssertEqual(detail.creatorName, "Tag Owner")
        XCTAssertEqual(detail.creatorEmail, "tagger@example.com")
        XCTAssertNotNil(detail.creatorDate)
    }

    func testReadsAnnotatedTagDetail() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        let hash = try makeCommit(in: repo)
        _ = try GitTagOperation.createAnnotated(
            named: "release/v1.0.0",
            at: hash,
            message: "First release",
            in: repo
        )

        let detail = try XCTUnwrap(GitTagReader.detail(named: "release/v1.0.0", in: repo))

        XCTAssertEqual(detail.name, "release/v1.0.0")
        XCTAssertEqual(detail.kind, .annotated)
        XCTAssertEqual(
            detail.targetHash,
            hash,
            "An annotated tag must resolve to the commit it points at, not to the tag object"
        )
        XCTAssertEqual(
            detail.targetSubject,
            "Initial commit subject",
            "The subject must come from the commit, not from the tag message"
        )
        XCTAssertEqual(detail.message, "First release")
        XCTAssertEqual(detail.creatorName, "Tag Owner")
        XCTAssertEqual(detail.creatorEmail, "tagger@example.com")
    }

    func testReadsMultiLineAnnotatedTagMessage() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        let hash = try makeCommit(in: repo)
        _ = try runGit(["tag", "-a", "notes-tag", hash, "-m", "Title line\n\nBody line"], in: repo)

        let detail = try XCTUnwrap(GitTagReader.detail(named: "notes-tag", in: repo))

        XCTAssertEqual(detail.kind, .annotated)
        XCTAssertEqual(
            detail.message,
            "Title line\n\nBody line",
            "The whole tag message must survive, including the blank line"
        )
    }

    func testReturnsNilForUnknownTag() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        _ = try makeCommit(in: repo)

        XCTAssertNil(GitTagReader.detail(named: "missing-tag", in: repo))
        XCTAssertNil(GitTagReader.detail(named: "  ", in: repo))
    }
}
