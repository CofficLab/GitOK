import XCTest
import GitOKCoreKit
@testable import PluginThemeOrchard

final class OrchardThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OrchardThemePlugin.metadata
        XCTAssertEqual(metadata.id, "ThemeOrchardPlugin")
        XCTAssertEqual(metadata.displayName, "Orchard Theme")
        XCTAssertEqual(metadata.description, "Earthy amber dark theme")
        XCTAssertEqual(metadata.iconName, "tray.full")
        XCTAssertEqual(metadata.order, 128)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "ThemeOrchard")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = OrchardThemePlugin.shared.themeContributions()
        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "stash")
        XCTAssertEqual(contributions[0].displayName, "Orchard")
        XCTAssertEqual(contributions[0].compactName, "Orchard")
        XCTAssertEqual(contributions[0].iconName, "tray.full")
        XCTAssertEqual(contributions[0].editorThemeId, "stash")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 128)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(Bundle.module.url(forResource: "ThemeOrchard", withExtension: "xcstrings"))
    }
}
