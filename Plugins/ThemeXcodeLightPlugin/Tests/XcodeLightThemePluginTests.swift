import XCTest
import GitOKCoreKit
@testable import ThemeXcodeLightPlugin

final class XcodeLightThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = XcodeLightThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeXcodeLightPlugin")
        XCTAssertEqual(metadata.displayName, "Xcode Light Theme")
        XCTAssertEqual(metadata.description, "Xcode-inspired light theme")
        XCTAssertEqual(metadata.iconName, "hammer")
        XCTAssertEqual(metadata.order, 137)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = XcodeLightThemePlugin.themeContributions(context: GitOKPluginContext())

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "xcode-light")
        XCTAssertEqual(contributions[0].displayName, "Xcode Light")
        XCTAssertEqual(contributions[0].compactName, "Xcode")
        XCTAssertEqual(contributions[0].iconName, "hammer")
        XCTAssertEqual(contributions[0].editorThemeId, "xcode-light")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 137)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}

