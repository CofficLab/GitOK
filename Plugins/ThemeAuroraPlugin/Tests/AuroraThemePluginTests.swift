import XCTest
import GitOKCoreKit
@testable import ThemeAuroraPlugin

final class AuroraThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = AuroraThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeAuroraPlugin")
        XCTAssertEqual(metadata.displayName, "Aurora Theme")
        XCTAssertEqual(metadata.description, "Deep cyan night theme")
        XCTAssertEqual(metadata.iconName, "point.3.connected.trianglepath.dotted")
        XCTAssertEqual(metadata.order, 122)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = AuroraThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "commit-graph")
        XCTAssertEqual(contributions[0].displayName, "Aurora")
        XCTAssertEqual(contributions[0].compactName, "Aurora")
        XCTAssertEqual(contributions[0].iconName, "point.3.connected.trianglepath.dotted")
        XCTAssertEqual(contributions[0].editorThemeId, "commit-graph")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 122)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}
