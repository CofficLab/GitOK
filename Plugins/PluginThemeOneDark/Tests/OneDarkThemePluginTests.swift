import XCTest
import GitOKCoreKit
@testable import PluginThemeOneDark

final class OneDarkThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OneDarkThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeOneDarkPlugin")
        XCTAssertEqual(metadata.displayName, "One Dark Theme")
        XCTAssertEqual(metadata.description, "Classic editor dark theme")
        XCTAssertEqual(metadata.iconName, "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(metadata.order, 136)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "ThemeOneDark")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = OneDarkThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "one-dark")
        XCTAssertEqual(contributions[0].displayName, "One Dark")
        XCTAssertEqual(contributions[0].compactName, "One")
        XCTAssertEqual(contributions[0].iconName, "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(contributions[0].editorThemeId, "one-dark")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 136)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "ThemeOneDark", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}

