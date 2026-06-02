import XCTest
import GitOKCoreKit
@testable import ThemeEmberPlugin

final class EmberThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = EmberThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeEmberPlugin")
        XCTAssertEqual(metadata.displayName, "Ember Theme")
        XCTAssertEqual(metadata.description, "Warm orange dark theme")
        XCTAssertEqual(metadata.iconName, "exclamationmark.triangle")
        XCTAssertEqual(metadata.order, 124)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = EmberThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "conflict")
        XCTAssertEqual(contributions[0].displayName, "Ember")
        XCTAssertEqual(contributions[0].compactName, "Ember")
        XCTAssertEqual(contributions[0].iconName, "exclamationmark.triangle")
        XCTAssertEqual(contributions[0].editorThemeId, "conflict")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 124)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}
