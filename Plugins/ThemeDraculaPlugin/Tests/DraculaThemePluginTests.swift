import XCTest
import GitOKCoreKit
@testable import ThemeDraculaPlugin

final class DraculaThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = DraculaThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeDraculaPlugin")
        XCTAssertEqual(metadata.displayName, "Dracula Theme")
        XCTAssertEqual(metadata.description, "Classic vivid dark theme")
        XCTAssertEqual(metadata.iconName, "moon.stars")
        XCTAssertEqual(metadata.order, 135)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = DraculaThemePlugin.themeContributions(context: GitOKPluginContext())

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "dracula")
        XCTAssertEqual(contributions[0].displayName, "Dracula")
        XCTAssertEqual(contributions[0].compactName, "Dracula")
        XCTAssertEqual(contributions[0].iconName, "moon.stars")
        XCTAssertEqual(contributions[0].editorThemeId, "dracula")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 135)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}

