import ProjectSupportKit
import XCTest
@testable import PluginReadme

final class ReadmePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = ReadmePlugin.metadata

        XCTAssertEqual(metadata.id, "ReadmePlugin")
        XCTAssertEqual(metadata.iconName, "book")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertTrue(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "Readme")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginReadmeLocalization.bundle.url(forResource: "Readme", withExtension: "xcstrings"))
        XCTAssertFalse(PluginReadmeLocalization.string("Readme").isEmpty)
        XCTAssertFalse(PluginReadmeLocalization.string("Provides README entry point in status bar").isEmpty)
    }

    @MainActor
    func testStatusBarContributionIsAvailable() {
        XCTAssertNotNil(ReadmePlugin.shared.statusBarTrailingView())
    }

    func testReadmeResolverFindsLowercaseCandidate() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try "fallback\n".write(to: directory.appendingPathComponent("readme.md"), atomically: true, encoding: .utf8)

        XCTAssertEqual(try ProjectDocumentResolver.readReadmeContent(in: directory), "fallback\n")
    }
}
