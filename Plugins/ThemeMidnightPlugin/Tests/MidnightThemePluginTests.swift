import XCTest
import GitOKCoreKit
@testable import ThemeMidnightPlugin

final class MidnightThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = MidnightThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeMidnightPlugin")
        XCTAssertEqual(metadata.displayName, "Midnight Theme")
        XCTAssertEqual(metadata.description, "Quiet terminal-green dark theme")
        XCTAssertEqual(metadata.iconName, "terminal")
        XCTAssertEqual(metadata.order, 123)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = MidnightThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "terminal")
        XCTAssertEqual(contributions[0].displayName, "Midnight")
        XCTAssertEqual(contributions[0].compactName, "Midnight")
        XCTAssertEqual(contributions[0].iconName, "terminal")
        XCTAssertEqual(contributions[0].editorThemeId, "terminal")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 123)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}
