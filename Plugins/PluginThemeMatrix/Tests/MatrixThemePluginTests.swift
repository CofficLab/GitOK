import XCTest
import GitOKCoreKit
@testable import PluginThemeMatrix

final class MatrixThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = MatrixThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeMatrixPlugin")
        XCTAssertEqual(metadata.displayName, "Matrix Theme")
        XCTAssertEqual(metadata.description, "Electric green dark theme")
        XCTAssertEqual(metadata.iconName, "gearshape.2")
        XCTAssertEqual(metadata.order, 131)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "ThemeMatrix")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = MatrixThemePlugin.shared.themeContributions()

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "automation")
        XCTAssertEqual(contributions[0].displayName, "Matrix")
        XCTAssertEqual(contributions[0].compactName, "Matrix")
        XCTAssertEqual(contributions[0].iconName, "gearshape.2")
        XCTAssertEqual(contributions[0].editorThemeId, "automation")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 131)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "ThemeMatrix", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}
