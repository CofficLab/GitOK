import XCTest
import GitOKCoreKit
@testable import ThemeGlacierPlugin

final class GlacierThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GlacierThemePlugin.metadata
        XCTAssertEqual(metadata.id, "ThemeGlacierPlugin")
        XCTAssertEqual(metadata.displayName, "Glacier Theme")
        XCTAssertEqual(metadata.description, "Icy cyan light theme")
        XCTAssertEqual(metadata.iconName, "externaldrive")
        XCTAssertEqual(metadata.order, 129)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = GlacierThemePlugin.shared.themeContributions()
        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "large-files")
        XCTAssertEqual(contributions[0].displayName, "Glacier")
        XCTAssertEqual(contributions[0].compactName, "Glacier")
        XCTAssertEqual(contributions[0].iconName, "externaldrive")
        XCTAssertEqual(contributions[0].editorThemeId, "large-files")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 129)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings"))
    }
}
