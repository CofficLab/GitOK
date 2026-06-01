import XCTest
@testable import PluginBannerTab

final class BannerTabPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = BannerTabPlugin.metadata

        XCTAssertEqual(metadata.id, "BannerTabPlugin")
        XCTAssertEqual(metadata.iconName, "rectangle.topthird.inset.filled")
        XCTAssertEqual(metadata.order, 2)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "BannerTab")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginBannerTabLocalization.bundle.url(forResource: "BannerTab", withExtension: "xcstrings"))
        XCTAssertFalse(PluginBannerTabLocalization.string("Banner").isEmpty)
        XCTAssertFalse(PluginBannerTabLocalization.string("Banner tab entry").isEmpty)
    }

    func testTabContributionIsAvailable() {
        XCTAssertEqual(BannerTabPlugin.shared.tabItem(), BannerTabPlugin.metadata.displayName)
    }
}
