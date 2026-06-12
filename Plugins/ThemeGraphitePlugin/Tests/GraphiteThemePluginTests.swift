import XCTest
import GitOKCoreKit
@testable import ThemeGraphitePlugin

final class GraphiteThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GraphiteThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeGraphitePlugin")
        XCTAssertEqual(metadata.displayName, "Graphite Theme")
        XCTAssertEqual(metadata.description, "Neutral graphite dark theme")
        XCTAssertEqual(metadata.iconName, "square.grid.3x3")
        XCTAssertEqual(metadata.order, 134)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = GraphiteThemePlugin.themeContributions(context: GitOKPluginContext())

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "graphite")
        XCTAssertEqual(contributions[0].displayName, "Graphite")
        XCTAssertEqual(contributions[0].compactName, "Graphite")
        XCTAssertEqual(contributions[0].iconName, "square.grid.3x3")
        XCTAssertEqual(contributions[0].editorThemeId, "graphite")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 134)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}

