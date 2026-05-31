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
        XCTAssertNotNil(L10n.bundle.url(forResource: "ActivityStatus", withExtension: "xcstrings"))
        XCTAssertFalse(L10n.string("Activity Status").isEmpty)
        XCTAssertFalse(L10n.string("Current activity").isEmpty)
    }

    @MainActor
    func testStatusBarCenterContributionIsAvailable() {
        let context = GitOKPluginContext()
        XCTAssertNotNil(ActivityStatusPlugin.shared.statusBarCenterView(context: context))
    }

    @MainActor
    func testStatusBarCenterViewWithActivityStatus() {
        let context = GitOKPluginContext(activityStatus: "Cloning repository...")
        XCTAssertNotNil(ActivityStatusPlugin.shared.statusBarCenterView(context: context))
    }

    @MainActor
    func testStatusBarCenterViewWithNilStatus() {
        let context = GitOKPluginContext(activityStatus: nil)
        // Should still return a view (the tile handles nil internally)
        XCTAssertNotNil(ActivityStatusPlugin.shared.statusBarCenterView(context: context))
    }
}
