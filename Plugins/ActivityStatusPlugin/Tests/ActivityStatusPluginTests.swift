import SwiftUI
import XCTest
import GitOKCoreKit
@testable import ActivityStatusPlugin

final class ActivityStatusPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = ActivityStatusPlugin.metadata

        XCTAssertEqual(metadata.id, "ActivityStatusPlugin")
        XCTAssertEqual(metadata.iconName, "arrow.triangle.2.circlepath")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(
            ActivityStatusPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        )
    }

    func testLocalizedStringsResolve() {
        let displayName = ActivityStatusPluginLocalization.string("Activity Status")
        XCTAssertFalse(displayName.isEmpty)

        let description = ActivityStatusPluginLocalization.string(
            "Displays current long-running activity in the status bar."
        )
        XCTAssertFalse(description.isEmpty)

        let tooltip = ActivityStatusPluginLocalization.string("Current activity")
        XCTAssertFalse(tooltip.isEmpty)
    }

    @MainActor
    func testStatusBarCenterItemsReturnsViewWithNonNilStatus() {
        let context = GitOKPluginContext(activityStatus: "Cloning repository...")
        XCTAssertFalse(ActivityStatusPlugin.statusBarCenterItems(context: context).isEmpty)
    }

    @MainActor
    func testStatusBarCenterItemsReturnsViewWithNilStatus() {
        let context = GitOKPluginContext(activityStatus: nil)
        XCTAssertFalse(ActivityStatusPlugin.statusBarCenterItems(context: context).isEmpty)
    }

    @MainActor
    func testStatusBarCenterItemsReturnsViewWithEmptyStatus() {
        let context = GitOKPluginContext(activityStatus: "")
        XCTAssertFalse(ActivityStatusPlugin.statusBarCenterItems(context: context).isEmpty)
    }

    @MainActor
    func testStatusBarCenterItemsReturnsViewWithDefaultContext() {
        let context = GitOKPluginContext()
        XCTAssertFalse(ActivityStatusPlugin.statusBarCenterItems(context: context).isEmpty)
    }

    @MainActor
    func testTileCanBeCreatedWithStatus() {
        let tile = ActivityStatusTile(activityStatus: "Pushing changes...")
        XCTAssertNotNil(tile.body)
    }

    @MainActor
    func testTileCanBeCreatedWithNilStatus() {
        let tile = ActivityStatusTile(activityStatus: nil)
        XCTAssertNotNil(tile.body)
    }

    @MainActor
    func testTileCanBeCreatedWithDefaultInit() {
        let tile = ActivityStatusTile()
        XCTAssertNotNil(tile.body)
    }
}
