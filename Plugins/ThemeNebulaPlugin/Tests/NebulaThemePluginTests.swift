import XCTest
import GitOKCoreKit
@testable import ThemeNebulaPlugin

final class NebulaThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = NebulaThemePlugin.metadata
        XCTAssertEqual(metadata.id, "ThemeNebulaPlugin")
        XCTAssertEqual(metadata.displayName, "Nebula Theme")
        XCTAssertEqual(metadata.description, "Violet atmospheric dark theme")
        XCTAssertEqual(metadata.iconName, "arrow.triangle.pull")
        XCTAssertEqual(metadata.order, 126)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "ThemeNebula")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = NebulaThemePlugin.shared.themeContributions()
        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "pull-request")
        XCTAssertEqual(contributions[0].displayName, "Nebula")
        XCTAssertEqual(contributions[0].compactName, "Nebula")
        XCTAssertEqual(contributions[0].iconName, "arrow.triangle.pull")
        XCTAssertEqual(contributions[0].editorThemeId, "pull-request")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 126)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(Bundle.module.url(forResource: "ThemeNebula", withExtension: "xcstrings"))
    }
}
