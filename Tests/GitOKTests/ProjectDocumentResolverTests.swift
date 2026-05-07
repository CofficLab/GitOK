import Foundation
import XCTest

final class ProjectDocumentResolverTests: XCTestCase {
    func testReadReadmeContentUsesFirstMatchingCandidate() throws {
        let repo = try TestWorkspace()
        try repo.write("Readme.md", content: "fallback\n")
        try repo.write("README.md", content: "preferred\n")

        XCTAssertEqual(
            try ProjectDocumentResolver.readReadmeContent(in: repo.url),
            "preferred\n"
        )
    }

    func testReadReadmeContentThrowsWhenMissing() throws {
        let repo = try TestWorkspace()

        XCTAssertThrowsError(try ProjectDocumentResolver.readReadmeContent(in: repo.url)) { error in
            XCTAssertEqual((error as NSError).localizedDescription, "README.md file not found")
        }
    }

    func testReadGitignoreContentReadsRootFile() throws {
        let repo = try TestWorkspace()
        try repo.write(".gitignore", content: "DerivedData/\n")

        XCTAssertEqual(
            try ProjectDocumentResolver.readGitignoreContent(in: repo.url),
            "DerivedData/\n"
        )
    }

    func testReadGitignoreContentThrowsWhenMissing() throws {
        let repo = try TestWorkspace()

        XCTAssertThrowsError(try ProjectDocumentResolver.readGitignoreContent(in: repo.url)) { error in
            XCTAssertEqual((error as NSError).localizedDescription, ".gitignore file not found")
        }
    }

    func testReadLicenseContentUsesFirstMatchingCandidate() throws {
        let repo = try TestWorkspace()
        try repo.write("license", content: "lowercase\n")
        try repo.write("LICENSE.txt", content: "text\n")
        try repo.write("LICENSE", content: "preferred\n")

        XCTAssertEqual(
            try ProjectDocumentResolver.readLicenseContent(in: repo.url),
            "preferred\n"
        )
    }

    func testReadLicenseContentThrowsWhenMissing() throws {
        let repo = try TestWorkspace()

        XCTAssertThrowsError(try ProjectDocumentResolver.readLicenseContent(in: repo.url)) { error in
            XCTAssertEqual((error as NSError).localizedDescription, "LICENSE file not found")
        }
    }
}

private final class TestWorkspace {
    let url: URL

    init() throws {
        let base = FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    func write(_ relativePath: String, content: String) throws {
        let fileURL = url.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.data(using: .utf8)?.write(to: fileURL)
    }
}
