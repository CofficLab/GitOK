import XCTest
import GitOKCoreKit
@testable import ThemeRiverPlugin

final class RiverThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = RiverThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeRiverPlugin")
        XCTAssertEqual(metadata.displayName, "River Theme")
        XCTAssertEqual(metadata.description, "Flowing teal dark theme")
        XCTAssertEqual(metadata.iconName, "arrow.triangle.branch")
        XCTAssertEqual(metadata.order, 125)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = RiverThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "branch-flow")
        XCTAssertEqual(contributions[0].displayName, "River")
        XCTAssertEqual(contributions[0].compactName, "River")
        XCTAssertEqual(contributions[0].iconName, "arrow.triangle.branch")
        XCTAssertEqual(contributions[0].editorThemeId, "branch-flow")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 125)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}
