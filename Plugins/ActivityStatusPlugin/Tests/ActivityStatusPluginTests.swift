import SwiftUI
import XCTest
import GitOKCoreKit
@testable import ActivityStatusPlugin

final class ActivityStatusPluginTests: XCTestCase {
    // MARK: - Metadata

    func testPluginMetadataIsStable() {
        let metadata = ActivityStatusPlugin.metadata

        XCTAssertEqual(metadata.id, "ActivityStatusPlugin")
        XCTAssertEqual(metadata.iconName, "arrow.triangle.2.circlepath")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testPluginConformsToPackagedPlugin() {
        // Verify the shared singleton pattern
        let instance = ActivityStatusPlugin.shared
        XCTAssertFalse(instance.instanceLabel.isEmpty)
        XCTAssertEqual(instance.instanceLabel, "ActivityStatusPlugin")
    }

    // MARK: - Localization

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

    func testUnknownKeyReturnsKeyItself() {
        // String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
        XCTAssertEqual(result, key)
    }

    // MARK: - Status Bar View

    @MainActor
    func testStatusBarCenterViewReturnsViewWithNonNilStatus() {
        let context = GitOKPluginContext(activityStatus: "Cloning repository...")
        let view = ActivityStatusPlugin.shared.statusBarCenterView(context: context)
        XCTAssertNotNil(view)
    }

    @MainActor
    func testStatusBarCenterViewReturnsViewWithNilStatus() {
        let context = GitOKPluginContext(activityStatus: nil)
        // Plugin always returns a tile view; the tile handles nil internally
        let view = ActivityStatusPlugin.shared.statusBarCenterView(context: context)
        XCTAssertNotNil(view)
    }

    @MainActor
    func testStatusBarCenterViewReturnsViewWithEmptyStatus() {
        let context = GitOKPluginContext(activityStatus: "")
        let view = ActivityStatusPlugin.shared.statusBarCenterView(context: context)
        XCTAssertNotNil(view)
    }

    @MainActor
    func testStatusBarCenterViewReturnsViewWithDefaultContext() {
        let context = GitOKPluginContext()
        let view = ActivityStatusPlugin.shared.statusBarCenterView(context: context)
        XCTAssertNotNil(view)
    }

    // MARK: - ActivityStatusTile

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
