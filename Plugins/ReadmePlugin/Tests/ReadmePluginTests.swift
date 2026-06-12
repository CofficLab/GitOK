import GitOKCoreKit
import ProjectSupportKit
import XCTest
@testable import ReadmePlugin

final class ReadmePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = ReadmePlugin.metadata

        XCTAssertEqual(metadata.id, "ReadmePlugin")
        XCTAssertEqual(metadata.iconName, "book")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(ReadmePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(ReadmePluginLocalization.string("Readme").isEmpty)
        XCTAssertFalse(ReadmePluginLocalization.string("Provides README entry point in status bar").isEmpty)
    }

    @MainActor
    func testStatusBarContributionIsAvailable() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"))
        XCTAssertFalse(ReadmePlugin.statusBarTrailingItems(context: context).isEmpty)
    }

    func testReadmeResolverFindsLowercaseCandidate() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try "fallback\n".write(to: directory.appendingPathComponent("readme.md"), atomically: true, encoding: .utf8)

        XCTAssertEqual(try ProjectDocumentResolver.readReadmeContent(in: directory), "fallback\n")
    }
}
