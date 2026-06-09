import XCTest
@testable import IconTabPlugin

final class IconTabPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = IconTabPlugin.metadata

        XCTAssertEqual(metadata.id, "IconTabPlugin")
        XCTAssertEqual(metadata.iconName, "photo")
        XCTAssertEqual(metadata.order, 1)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(IconTabPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(IconTabPluginLocalization.string("Icon").isEmpty)
        XCTAssertFalse(IconTabPluginLocalization.string("Icon management").isEmpty)
    }

    func testTabContributionIsAvailable() {
        XCTAssertEqual(IconTabPlugin.shared.tabItem(), IconTabPlugin.metadata.displayName)
    }
}
