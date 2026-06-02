import XCTest
import GitOKCoreKit
@testable import ThemeMountainPlugin

final class MountainThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = MountainThemePlugin.metadata
        XCTAssertEqual(metadata.id, "ThemeMountainPlugin")
        XCTAssertEqual(metadata.displayName, "Mountain Theme")
        XCTAssertEqual(metadata.description, "Quiet stone light theme")
        XCTAssertEqual(metadata.iconName, "archivebox")
        XCTAssertEqual(metadata.order, 132)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "ThemeMountain")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = MountainThemePlugin.shared.themeContributions()
        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "archive")
        XCTAssertEqual(contributions[0].displayName, "Mountain")
        XCTAssertEqual(contributions[0].compactName, "Mountain")
        XCTAssertEqual(contributions[0].iconName, "archivebox")
        XCTAssertEqual(contributions[0].editorThemeId, "archive")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 132)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(Bundle.module.url(forResource: "ThemeMountain", withExtension: "xcstrings"))
    }
}
