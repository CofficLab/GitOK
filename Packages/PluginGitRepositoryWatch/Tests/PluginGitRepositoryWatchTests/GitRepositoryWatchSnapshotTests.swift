import Foundation
import XCTest
@testable import PluginGitRepositoryWatch

/// `GitDirectoryResolver` 的解析与指纹逻辑覆盖。
///
/// 这些用例全部使用临时目录里手工构造的 `.git` 目录，不依赖真实仓库，
/// 因此可以稳定地覆盖 worktree 解析、`packed-refs` 回退、stash / refs
/// 指纹组合等分支。
final class GitDirectoryWatchSnapshotTests: XCTestCase {

    // MARK: - Helpers

    private func makeTemporaryDirectory(_ label: String = "gitok-watch") throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(label)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func write(_ contents: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - resolveGitDirectory

    func testResolveGitDirectoryReturnsDotGitDirectoryForPlainRepository() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let dotGit = root.appendingPathComponent(".git")
        try FileManager.default.createDirectory(at: dotGit, withIntermediateDirectories: true)

        let resolved = try GitDirectoryResolver.resolveGitDirectory(for: root)

        XCTAssertEqual(resolved.standardizedFileURL.path, dotGit.standardizedFileURL.path)
    }

    func testResolveGitDirectoryResolvesRelativeWorktreePointer() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let external = root.appendingPathComponent("external-git")
        try FileManager.default.createDirectory(at: external, withIntermediateDirectories: true)
        try write("gitdir: external-git\n", to: root.appendingPathComponent(".git"))

        let resolved = try GitDirectoryResolver.resolveGitDirectory(for: root)

        XCTAssertEqual(resolved.standardizedFileURL.path, external.standardizedFileURL.path)
    }

    func testResolveGitDirectoryResolvesAbsoluteWorktreePointer() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let external = try makeTemporaryDirectory("gitok-watch-external")
        defer { try? FileManager.default.removeItem(at: external) }
        try write("gitdir: \(external.path)\n", to: root.appendingPathComponent(".git"))

        let resolved = try GitDirectoryResolver.resolveGitDirectory(for: root)

        XCTAssertEqual(resolved.standardizedFileURL.path, external.standardizedFileURL.path)
    }

    func testResolveGitDirectoryThrowsForUnparsableGitFile() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("this is not a gitdir pointer\n", to: root.appendingPathComponent(".git"))

        XCTAssertThrowsError(try GitDirectoryResolver.resolveGitDirectory(for: root)) { error in
            guard case GitDirectoryResolver.ResolverError.invalidGitFile = error else {
                XCTFail("expected invalidGitFile, got \(error)")
                return
            }
        }
    }

    // MARK: - readHeadHash / readHeadRef

    func testReadHeadHashPrefersLooseRefOverPackedRefs() throws {
        let gitDir = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: gitDir) }
        try write("ref: refs/heads/main\n", to: gitDir.appendingPathComponent("HEAD"))
        try write("loose-hash\n", to: gitDir.appendingPathComponent("refs/heads/main"))
        try write(
            "# pack-refs with: peeled fully-peeled sorted \npacked-hash refs/heads/main\n",
            to: gitDir.appendingPathComponent("packed-refs")
        )

        XCTAssertEqual(GitDirectoryResolver.readHeadHash(gitDirectory: gitDir), "loose-hash")
    }

    func testReadHeadHashFallsBackToPackedRefs() throws {
        let gitDir = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: gitDir) }
        try write("ref: refs/heads/main\n", to: gitDir.appendingPathComponent("HEAD"))
        try write(
            "# pack-refs with: peeled fully-peeled sorted \npacked-hash refs/heads/main\n^peeled-hash\n",
            to: gitDir.appendingPathComponent("packed-refs")
        )

        XCTAssertEqual(GitDirectoryResolver.readHeadHash(gitDirectory: gitDir), "packed-hash")
    }

    func testReadHeadHashIgnoresCommentAndPeeledLinesInPackedRefs() throws {
        let gitDir = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: gitDir) }
        try write("ref: refs/heads/main\n", to: gitDir.appendingPathComponent("HEAD"))
        try write(
            "# pack-refs with: peeled fully-peeled sorted \n^peeled-hash\nother-hash refs/heads/other\n",
            to: gitDir.appendingPathComponent("packed-refs")
        )

        XCTAssertNil(GitDirectoryResolver.readHeadHash(gitDirectory: gitDir))
    }

    func testReadHeadHashReturnsNilForMissingOrBlankHead() throws {
        let gitDir = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: gitDir) }

        XCTAssertNil(GitDirectoryResolver.readHeadHash(gitDirectory: gitDir))

        try write("   \n", to: gitDir.appendingPathComponent("HEAD"))
        XCTAssertNil(GitDirectoryResolver.readHeadHash(gitDirectory: gitDir))
    }

    func testReadHeadRefReturnsNilForDetachedOrEmptyReference() throws {
        let gitDir = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: gitDir) }

        try write("deadbeef\n", to: gitDir.appendingPathComponent("HEAD"))
        XCTAssertNil(GitDirectoryResolver.readHeadRef(gitDirectory: gitDir))

        try write("ref:\n", to: gitDir.appendingPathComponent("HEAD"))
        XCTAssertNil(GitDirectoryResolver.readHeadRef(gitDirectory: gitDir))

        try write("ref: refs/heads/dev\n", to: gitDir.appendingPathComponent("HEAD"))
        XCTAssertEqual(GitDirectoryResolver.readHeadRef(gitDirectory: gitDir), "refs/heads/dev")
    }

    // MARK: - readSnapshot

    func testReadSnapshotCapturesEveryDimension() throws {
        let gitDir = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: gitDir) }
        try write("ref: refs/heads/main\n", to: gitDir.appendingPathComponent("HEAD"))
        try write("head-hash\n", to: gitDir.appendingPathComponent("refs/heads/main"))
        try write("feature-hash\n", to: gitDir.appendingPathComponent("refs/heads/feature"))
        try write("index-content\n", to: gitDir.appendingPathComponent("index"))
        try write("stash-hash\n", to: gitDir.appendingPathComponent("refs/stash"))
        try write("stash-log\n", to: gitDir.appendingPathComponent("logs/refs/stash"))

        let snapshot = GitDirectoryResolver.readSnapshot(gitDirectory: gitDir)

        XCTAssertEqual(snapshot.head, "head-hash")
        XCTAssertEqual(snapshot.headRef, "refs/heads/main")
        XCTAssertEqual(
            snapshot.index,
            GitDirectoryResolver.fileContentFingerprint(gitDir.appendingPathComponent("index"))
        )
        XCTAssertNotNil(snapshot.stash)
        let refs = try XCTUnwrap(snapshot.refs)
        XCTAssertTrue(refs.contains("main="), "refs 指纹应包含 main 分支：\(refs)")
        XCTAssertTrue(refs.contains("feature="), "refs 指纹应包含 feature 分支：\(refs)")
    }

    func testReadSnapshotOnEmptyGitDirectoryHasNoFingerprints() throws {
        let gitDir = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: gitDir) }

        let snapshot = GitDirectoryResolver.readSnapshot(gitDirectory: gitDir)

        XCTAssertNil(snapshot.head)
        XCTAssertNil(snapshot.headRef)
        XCTAssertNil(snapshot.index)
        XCTAssertNil(snapshot.stash)
        XCTAssertNil(snapshot.refs)
    }

    func testReadSnapshotStashFingerprintCombinesRefsAndLogs() throws {
        let gitDir = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: gitDir) }
        let refsStash = gitDir.appendingPathComponent("refs/stash")
        let logsStash = gitDir.appendingPathComponent("logs/refs/stash")
        try write("stash\n", to: refsStash)
        try write("stash-log\n", to: logsStash)

        let snapshot = GitDirectoryResolver.readSnapshot(gitDirectory: gitDir)
        let expectedRefs = try XCTUnwrap(GitDirectoryResolver.fileContentFingerprint(refsStash))
        let expectedLogs = try XCTUnwrap(GitDirectoryResolver.fileContentFingerprint(logsStash))

        XCTAssertEqual(snapshot.stash, "\(expectedRefs):\(expectedLogs)")
    }

    func testReadSnapshotStashFingerprintUsesSingleAvailableSource() throws {
        // 只剩 refs/stash。
        let refsOnly = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: refsOnly) }
        let refsStash = refsOnly.appendingPathComponent("refs/stash")
        try write("stash\n", to: refsStash)
        var snapshot = GitDirectoryResolver.readSnapshot(gitDirectory: refsOnly)
        XCTAssertEqual(
            snapshot.stash,
            GitDirectoryResolver.fileContentFingerprint(refsStash)
        )

        // 只剩 logs/refs/stash。
        let logsOnly = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: logsOnly) }
        let logsStash = logsOnly.appendingPathComponent("logs/refs/stash")
        try write("stash-log\n", to: logsStash)
        snapshot = GitDirectoryResolver.readSnapshot(gitDirectory: logsOnly)
        XCTAssertEqual(
            snapshot.stash,
            GitDirectoryResolver.fileContentFingerprint(logsStash)
        )

        // 两者都不存在。
        let none = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: none) }
        snapshot = GitDirectoryResolver.readSnapshot(gitDirectory: none)
        XCTAssertNil(snapshot.stash)
    }

    func testReadSnapshotRefsFingerprintIncludesNestedRefFiles() throws {
        let gitDir = try makeTemporaryDirectory("gitok-watch-git")
        defer { try? FileManager.default.removeItem(at: gitDir) }
        try write("main-hash\n", to: gitDir.appendingPathComponent("refs/heads/main"))
        try write("inner-hash\n", to: gitDir.appendingPathComponent("refs/heads/nested/inner"))

        let snapshot = GitDirectoryResolver.readSnapshot(gitDirectory: gitDir)
        let refs = try XCTUnwrap(snapshot.refs)

        XCTAssertTrue(refs.contains("main="), "refs 指纹应包含 main：\(refs)")
        XCTAssertTrue(refs.contains("nested/inner="), "refs 指纹应包含嵌套 ref：\(refs)")
    }

    // MARK: - fileContentFingerprint

    func testFileContentFingerprintDistinguishesSameSizeContents() throws {
        let root = try makeTemporaryDirectory("gitok-watch-fingerprint")
        defer { try? FileManager.default.removeItem(at: root) }
        let fileURL = root.appendingPathComponent("same-size.txt")

        try write("aaaa", to: fileURL)
        let first = try XCTUnwrap(GitDirectoryResolver.fileContentFingerprint(fileURL))
        try write("bbbb", to: fileURL)
        let second = try XCTUnwrap(GitDirectoryResolver.fileContentFingerprint(fileURL))

        XCTAssertNotEqual(first, second, "同尺寸不同内容必须产生不同指纹")
        XCTAssertEqual(first.split(separator: ":").first, "4")
        XCTAssertEqual(second.split(separator: ":").first, "4")
    }

    func testFileContentFingerprintIsNilForMissingFile() {
        let missing = URL(fileURLWithPath: "/non-existent-\(UUID().uuidString)")
        XCTAssertNil(GitDirectoryResolver.fileContentFingerprint(missing))
    }
}
