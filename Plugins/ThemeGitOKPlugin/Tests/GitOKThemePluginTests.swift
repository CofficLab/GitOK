import SwiftUI
import XCTest
import GitOKCoreKit
@testable import ThemeGitOKPlugin

final class GitOKThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GitOKThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeGitOKPlugin")
        XCTAssertEqual(metadata.displayName, "GitOK Theme")
        XCTAssertEqual(metadata.description, "Default GitOK dark theme")
        XCTAssertEqual(metadata.iconName, "folder.badge.gearshape")
        XCTAssertEqual(metadata.order, 120)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "ThemeGitOK")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = GitOKThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "repository")
        XCTAssertEqual(contributions[0].displayName, "GitOK")
        XCTAssertEqual(contributions[0].compactName, "GitOK")
        XCTAssertEqual(contributions[0].iconName, "folder.badge.gearshape")
        XCTAssertEqual(contributions[0].editorThemeId, "repository")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 120)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "ThemeGitOK", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}
