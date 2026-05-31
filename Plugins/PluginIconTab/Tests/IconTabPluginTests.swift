import XCTest
@testable import PluginIconTab

final class IconTabPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = IconTabPlugin.metadata

        XCTAssertEqual(metadata.id, "IconTabPlugin")
        XCTAssertEqual(metadata.iconName, "photo")
        XCTAssertEqual(metadata.order, 1)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "IconTab")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginIconTabLocalization.bundle.url(forResource: "IconTab", withExtension: "xcstrings"))
        XCTAssertFalse(PluginIconTabLocalization.string("Icon").isEmpty)
        XCTAssertFalse(PluginIconTabLocalization.string("Icon management").isEmpty)
    }

    func testTabContributionIsAvailable() {
        XCTAssertEqual(IconTabPlugin.shared.tabItem(), IconTabPlugin.metadata.displayName)
    }
}
