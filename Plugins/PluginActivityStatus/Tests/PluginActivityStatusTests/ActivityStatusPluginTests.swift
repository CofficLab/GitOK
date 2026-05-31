import XCTest
@testable import PluginActivityStatus

final class ActivityStatusPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = ActivityStatusPlugin.metadata

        XCTAssertEqual(metadata.id, "ActivityStatusPlugin")
        XCTAssertEqual(metadata.iconName, "arrow.triangle.2.circlepath")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "ActivityStatus")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginActivityStatusLocalization.bundle.url(forResource: "ActivityStatus", withExtension: "xcstrings"))
        XCTAssertFalse(PluginActivityStatusLocalization.string("Activity Status").isEmpty)
        XCTAssertFalse(PluginActivityStatusLocalization.string("Current activity").isEmpty)
    }

    @MainActor
    func testStatusBarCenterContributionIsAvailable() {
        XCTAssertNotNil(ActivityStatusPlugin.shared.statusBarCenterView(context: GitOKPluginContext()))
    }
}
