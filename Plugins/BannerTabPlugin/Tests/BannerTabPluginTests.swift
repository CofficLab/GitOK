import XCTest
@testable import BannerTabPlugin

final class BannerTabPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = BannerTabPlugin.metadata

        XCTAssertEqual(metadata.id, "BannerTabPlugin")
        XCTAssertEqual(metadata.iconName, "rectangle.topthird.inset.filled")
        XCTAssertEqual(metadata.order, 2)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(BannerTabPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(BannerTabPluginLocalization.string("Banner").isEmpty)
        XCTAssertFalse(BannerTabPluginLocalization.string("Banner tab entry").isEmpty)
    }

    func testTabContributionIsAvailable() {
        XCTAssertEqual(BannerTabPlugin.shared.tabItem(), BannerTabPlugin.metadata.displayName)
    }
}
