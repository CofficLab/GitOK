import XCTest
@testable import PluginGitTab

final class GitTabPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GitTabPlugin.metadata

        XCTAssertEqual(metadata.id, "GitTabPlugin")
        XCTAssertEqual(metadata.iconName, "arrow.up.arrow.down")
        XCTAssertEqual(metadata.order, 0)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "GitTab")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginGitTabLocalization.bundle.url(forResource: "GitTab", withExtension: "xcstrings"))
        XCTAssertFalse(PluginGitTabLocalization.string("Git").isEmpty)
        XCTAssertFalse(PluginGitTabLocalization.string("Git version control").isEmpty)
    }

    func testTabContributionIsAvailable() {
        XCTAssertEqual(GitTabPlugin.shared.tabItem(), GitTabPlugin.metadata.displayName)
    }
}
