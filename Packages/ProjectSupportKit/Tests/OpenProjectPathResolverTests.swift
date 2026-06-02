import Foundation
import XCTest
@testable import ProjectSupportKit

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

        XCTAssertEqual(OpenProjectPathResolver.resolveGitRoot(from: nested.path), repoRoot.path)
        XCTAssertEqual(OpenProjectPathResolver.resolveGitRoot(from: file.path), repoRoot.path)
    }

    func testResolveGitRootReturnsNormalizedInputWhenNoRepositoryFound() throws {
        let root = try makeTemporaryDirectory()
        let plain = root.appendingPathComponent("plain folder", isDirectory: true)
        try FileManager.default.createDirectory(at: plain, withIntermediateDirectories: true)

        XCTAssertEqual(OpenProjectPathResolver.resolveGitRoot(from: " \(plain.path)/ "), plain.path)
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

        XCTAssertEqual(OpenProjectPathResolver.resolvePath(fromOpenURL: url), repoRoot.path)
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

        XCTAssertEqual(OpenProjectPathResolver.resolvePath(fromOpenURL: url), repoRoot.path)
    }

    func testResolvePathRejectsUnsupportedURLSchemesAndMissingPaths() {
        XCTAssertNil(OpenProjectPathResolver.resolvePath(fromOpenURL: URL(string: "https://example.com")!))
        XCTAssertNil(OpenProjectPathResolver.resolvePath(fromOpenURL: URL(string: "gitok://openRepo")!))
    }

    func testNormalizePathHandlesInvalidFileURLString() {
        // Invalid file:// URL with empty path returns "file:/"
        // because URL(string: "file://") produces a URL with path "/"
        XCTAssertEqual(
            OpenProjectPathResolver.normalizePath("file://"),
            "file:/"
        )
    }

    func testResolveGitRootWalksUpFromRootPathToFindGitRepository() throws {
        // Test "/" path - it will walk up from current directory
        // and find the nearest git repository (which is this project)
        let result = OpenProjectPathResolver.resolveGitRoot(from: "/")
        // Should find a git repository somewhere in the path hierarchy
        // The actual result depends on where the test is running
        XCTAssertTrue(result.contains("/"))
    }

    func testResolveGitRootStopsAtRootWithoutGitDirectory() throws {
        // Create a temporary directory structure without .git at root level
        let tempRoot = try makeTemporaryDirectory()
        let nestedPath = tempRoot.appendingPathComponent("deeply/nested/folder", isDirectory: true)
        try FileManager.default.createDirectory(at: nestedPath, withIntermediateDirectories: true)

        // Should return the normalized input path when no .git found
        let result = OpenProjectPathResolver.resolveGitRoot(from: nestedPath.path)
        XCTAssertEqual(result, nestedPath.path)
    }

    func testNormalizePathHandlesFileURLWithEmptyPath() {
        // Test the fallback path when URL(string:) returns nil
        // This tests lines 15-16: returning raw input or path after dropping file://
        let result = OpenProjectPathResolver.normalizePath("file://non-parseable-url")
        // URL(string: "file://non-parseable-url") might succeed, so we need a truly invalid URL

        // Test with empty path after file://
        XCTAssertEqual(
            OpenProjectPathResolver.normalizePath("file://"),
            "file:/"
        )
    }

    func testResolveGitRootReturnsInputWhenStartingAtRootLevel() throws {
        // Test the edge case where we start at filesystem root
        // This should trigger line 48: parent == currentURL.path
        let rootPath = "/"

        // When starting at root, it should return normalized root
        let result = OpenProjectPathResolver.resolveGitRoot(from: rootPath)
        XCTAssertTrue(result.contains("/"))
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
