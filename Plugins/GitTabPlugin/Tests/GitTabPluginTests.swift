import XCTest
@testable import GitTabPlugin

final class GitTabPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GitTabPlugin.metadata

        XCTAssertEqual(metadata.id, "GitTabPlugin")
        XCTAssertEqual(metadata.iconName, "arrow.up.arrow.down")
        XCTAssertEqual(metadata.order, 0)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(GitTabPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(GitTabPluginLocalization.string("Git").isEmpty)
        XCTAssertFalse(GitTabPluginLocalization.string("Git version control").isEmpty)
    }

    func testTabContributionIsAvailable() {
        XCTAssertEqual(GitTabPlugin.shared.tabItem(), GitTabPlugin.metadata.displayName)
    }
}
