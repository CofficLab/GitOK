import XCTest
import GitOKCoreKit
@testable import ThemeWinterPlugin

final class WinterThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = WinterThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeWinterPlugin")
        XCTAssertEqual(metadata.displayName, "Winter Theme")
        XCTAssertEqual(metadata.description, "Cool minimal light theme")
        XCTAssertEqual(metadata.iconName, "scope")
        XCTAssertEqual(metadata.order, 133)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = WinterThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "focus")
        XCTAssertEqual(contributions[0].displayName, "Winter")
        XCTAssertEqual(contributions[0].compactName, "Winter")
        XCTAssertEqual(contributions[0].iconName, "scope")
        XCTAssertEqual(contributions[0].editorThemeId, "focus")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 133)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}

