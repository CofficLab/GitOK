import XCTest
import GitOKCoreKit
@testable import PluginThemeStatusBar

final class ThemeStatusBarPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = ThemeStatusBarPlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeStatusBarPlugin")
        XCTAssertEqual(metadata.iconName, "paintbrush")
        XCTAssertEqual(metadata.order, 119)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "ThemeStatusBar")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginThemeStatusBarLocalization.bundle.url(forResource: "ThemeStatusBar", withExtension: "xcstrings"))
        XCTAssertFalse(PluginThemeStatusBarLocalization.string("Theme Status").isEmpty)
        XCTAssertFalse(PluginThemeStatusBarLocalization.string("Switch themes from the status bar").isEmpty)
    }

    @MainActor
    func testStatusBarContributionIsAvailable() {
        XCTAssertNotNil(ThemeStatusBarPlugin.shared.statusBarTrailingView(context: GitOKPluginContext()))
    }
}
