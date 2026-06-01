import XCTest
import GitOKCoreKit
@testable import PluginThemeSummer

final class SummerThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = SummerThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeSummerPlugin")
        XCTAssertEqual(metadata.displayName, "Summer Theme")
        XCTAssertEqual(metadata.description, "Warm golden light theme")
        XCTAssertEqual(metadata.iconName, "tag")
        XCTAssertEqual(metadata.order, 130)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "ThemeSummer")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = SummerThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "release")
        XCTAssertEqual(contributions[0].displayName, "Summer")
        XCTAssertEqual(contributions[0].compactName, "Summer")
        XCTAssertEqual(contributions[0].iconName, "tag")
        XCTAssertEqual(contributions[0].editorThemeId, "release")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 130)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "ThemeSummer", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}

