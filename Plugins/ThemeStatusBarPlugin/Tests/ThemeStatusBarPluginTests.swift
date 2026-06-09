import XCTest
import GitOKCoreKit
@testable import ThemeStatusBarPlugin

final class ThemeStatusBarPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = ThemeStatusBarPlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeStatusBarPlugin")
        XCTAssertEqual(metadata.iconName, "paintbrush")
        XCTAssertEqual(metadata.order, 119)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(ThemeStatusBarPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(ThemeStatusBarPluginLocalization.string("Theme Status").isEmpty)
        XCTAssertFalse(ThemeStatusBarPluginLocalization.string("Switch themes from the status bar").isEmpty)
    }

    @MainActor
    func testStatusBarContributionIsAvailable() {
        XCTAssertNotNil(ThemeStatusBarPlugin.shared.statusBarTrailingView(context: GitOKPluginContext()))
    }
}
