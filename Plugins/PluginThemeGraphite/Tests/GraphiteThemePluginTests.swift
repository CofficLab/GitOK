import XCTest
import GitOKCoreKit
@testable import PluginThemeGraphite

final class GraphiteThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GraphiteThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeGraphitePlugin")
        XCTAssertEqual(metadata.displayName, "Graphite Theme")
        XCTAssertEqual(metadata.description, "Neutral graphite dark theme")
        XCTAssertEqual(metadata.iconName, "square.grid.3x3")
        XCTAssertEqual(metadata.order, 134)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "ThemeGraphite")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = GraphiteThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "graphite")
        XCTAssertEqual(contributions[0].displayName, "Graphite")
        XCTAssertEqual(contributions[0].compactName, "Graphite")
        XCTAssertEqual(contributions[0].iconName, "square.grid.3x3")
        XCTAssertEqual(contributions[0].editorThemeId, "graphite")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 134)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "ThemeGraphite", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}

