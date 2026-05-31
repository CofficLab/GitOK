import XCTest
@testable import PluginThemeHarbor

final class HarborThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = HarborThemePlugin.metadata
        XCTAssertEqual(metadata.id, "ThemeHarborPlugin")
        XCTAssertEqual(metadata.displayName, "Harbor Theme")
        XCTAssertEqual(metadata.description, "Deep blue water theme")
        XCTAssertEqual(metadata.iconName, "network")
        XCTAssertEqual(metadata.order, 127)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "ThemeHarbor")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = HarborThemePlugin.shared.themeContributions()
        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "remote")
        XCTAssertEqual(contributions[0].displayName, "Harbor")
        XCTAssertEqual(contributions[0].compactName, "Harbor")
        XCTAssertEqual(contributions[0].iconName, "network")
        XCTAssertEqual(contributions[0].editorThemeId, "remote")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 127)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(Bundle.module.url(forResource: "ThemeHarbor", withExtension: "xcstrings"))
    }
}
