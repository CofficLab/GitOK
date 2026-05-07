import Foundation
import XCTest

final class OpenProjectPathResolverTests: XCTestCase {
    func testNormalizePathTrimsWhitespaceDecodesPercentEscapesAndRemovesTrailingSlash() {
        XCTAssertEqual(
            OpenProjectPathResolver.normalizePath("  /tmp/my%20repo/ \n"),
            "/tmp/my repo"
        )
    }

    func testNormalizePathSupportsFileURLStrings() {
        XCTAssertEqual(
            OpenProjectPathResolver.normalizePath("file:///tmp/project"),
            "/tmp/project"
        )
    }

    func testResolveGitRootWalksUpFromNestedDirectoryAndFile() throws {
        let root = try makeTemporaryDirectory()
        let repoRoot = root.appendingPathComponent("repo", isDirectory: true)
        let nested = repoRoot.appendingPathComponent("Sources/Feature", isDirectory: true)
        let file = nested.appendingPathComponent("File.swift", isDirectory: false)

        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: repoRoot.appendingPathComponent(".git", isDirectory: true),
            withIntermediateDirectories: true
        )
        try "content".write(to: file, atomically: true, encoding: .utf8)

        XCTAssertEqual(
            OpenProjectPathResolver.resolveGitRoot(from: nested.path),
            repoRoot.path
        )
        XCTAssertEqual(
            OpenProjectPathResolver.resolveGitRoot(from: file.path),
            repoRoot.path
        )
    }

    func testResolveGitRootReturnsNormalizedInputWhenNoRepositoryFound() throws {
        let root = try makeTemporaryDirectory()
        let plain = root.appendingPathComponent("plain folder", isDirectory: true)
        try FileManager.default.createDirectory(at: plain, withIntermediateDirectories: true)

        XCTAssertEqual(
            OpenProjectPathResolver.resolveGitRoot(from: " \(plain.path)/ "),
            plain.path
        )
    }

    func testResolvePathSupportsOpenRepoQueryURL() throws {
        let root = try makeTemporaryDirectory()
        let repoRoot = root.appendingPathComponent("query repo", isDirectory: true)
        try FileManager.default.createDirectory(at: repoRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: repoRoot.appendingPathComponent(".git", isDirectory: true),
            withIntermediateDirectories: true
        )

        let encodedPath = repoRoot.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = try XCTUnwrap(URL(string: "gitok://openRepo?path=\(encodedPath)"))

        XCTAssertEqual(
            OpenProjectPathResolver.resolvePath(fromOpenURL: url),
            repoRoot.path
        )
    }

    func testResolvePathSupportsDirectPathURL() throws {
        let root = try makeTemporaryDirectory()
        let repoRoot = root.appendingPathComponent("direct-repo", isDirectory: true)
        let nested = repoRoot.appendingPathComponent("Packages/App", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: repoRoot.appendingPathComponent(".git", isDirectory: true),
            withIntermediateDirectories: true
        )

        let url = try XCTUnwrap(URL(string: "gitok:///\(nested.path.dropFirst())"))

        XCTAssertEqual(
            OpenProjectPathResolver.resolvePath(fromOpenURL: url),
            repoRoot.path
        )
    }

    func testResolvePathRejectsUnsupportedURLSchemesAndMissingPaths() {
        XCTAssertNil(OpenProjectPathResolver.resolvePath(fromOpenURL: URL(string: "https://example.com")!))
        XCTAssertNil(OpenProjectPathResolver.resolvePath(fromOpenURL: URL(string: "gitok://openRepo")!))
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory
    }
}
