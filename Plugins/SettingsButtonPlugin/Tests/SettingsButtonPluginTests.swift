import GitOKCoreKit
import XCTest
@testable import SettingsButtonPlugin

final class SettingsButtonPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = SettingsButtonPlugin.metadata

        XCTAssertEqual(metadata.id, "SettingsButton")
        XCTAssertEqual(metadata.iconName, "gearshape")
        XCTAssertEqual(metadata.order, 9000)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "SettingsButton")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(SettingsButtonPluginLocalization.bundle.url(forResource: "SettingsButton", withExtension: "xcstrings"))
        XCTAssertFalse(SettingsButtonPluginLocalization.string("Settings Button").isEmpty)
        XCTAssertFalse(SettingsButtonPluginLocalization.string("Open Settings").isEmpty)
    }

    @MainActor
    func testStatusBarContributionIsAvailable() {
        XCTAssertNotNil(SettingsButtonPlugin.shared.statusBarTrailingView(context: GitOKPluginContext()))
    }
}
