import XCTest
import GitOKCoreKit
@testable import ThemeSpringPlugin

final class SpringThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = SpringThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeSpringPlugin")
        XCTAssertEqual(metadata.displayName, "Spring Theme")
        XCTAssertEqual(metadata.description, "Fresh green light theme")
        XCTAssertEqual(metadata.iconName, "tree")
        XCTAssertEqual(metadata.order, 121)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = SpringThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "worktree")
        XCTAssertEqual(contributions[0].displayName, "Spring")
        XCTAssertEqual(contributions[0].compactName, "Spring")
        XCTAssertEqual(contributions[0].iconName, "tree")
        XCTAssertEqual(contributions[0].editorThemeId, "worktree")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 121)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}
