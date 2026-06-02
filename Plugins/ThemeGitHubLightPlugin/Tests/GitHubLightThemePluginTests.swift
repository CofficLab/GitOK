import XCTest
import GitOKCoreKit
@testable import ThemeGitHubLightPlugin

final class GitHubLightThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GitHubLightThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeGitHubLightPlugin")
        XCTAssertEqual(metadata.displayName, "GitHub Light Theme")
        XCTAssertEqual(metadata.description, "GitHub-inspired light theme")
        XCTAssertEqual(metadata.iconName, "globe")
        XCTAssertEqual(metadata.order, 138)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = GitHubLightThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "github-light")
        XCTAssertEqual(contributions[0].displayName, "GitHub Light")
        XCTAssertEqual(contributions[0].compactName, "GitHub")
        XCTAssertEqual(contributions[0].iconName, "globe")
        XCTAssertEqual(contributions[0].editorThemeId, "github-light")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 138)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}
