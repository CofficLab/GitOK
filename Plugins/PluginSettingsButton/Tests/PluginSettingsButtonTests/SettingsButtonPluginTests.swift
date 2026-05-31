import XCTest
@testable import PluginSettingsButton

final class SettingsButtonPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = SettingsButtonPlugin.metadata

        XCTAssertEqual(metadata.id, "SettingsButton")
        XCTAssertEqual(metadata.iconName, "gearshape")
        XCTAssertEqual(metadata.order, 9000)
        XCTAssertTrue(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "SettingsButton")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginSettingsButtonLocalization.bundle.url(forResource: "SettingsButton", withExtension: "xcstrings"))
        XCTAssertFalse(PluginSettingsButtonLocalization.string("Settings Button").isEmpty)
        XCTAssertFalse(PluginSettingsButtonLocalization.string("Open Settings").isEmpty)
    }

    @MainActor
    func testStatusBarContributionIsAvailable() {
        XCTAssertNotNil(SettingsButtonPlugin.shared.statusBarTrailingView(context: GitOKPluginContext()))
    }
}
