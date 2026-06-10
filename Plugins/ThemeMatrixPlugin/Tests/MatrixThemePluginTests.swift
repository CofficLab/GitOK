import XCTest
import GitOKCoreKit
@testable import ThemeMatrixPlugin

final class MatrixThemePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = MatrixThemePlugin.metadata

        XCTAssertEqual(metadata.id, "ThemeMatrixPlugin")
        XCTAssertEqual(metadata.displayName, "Matrix Theme")
        XCTAssertEqual(metadata.description, "Electric green dark theme")
        XCTAssertEqual(metadata.iconName, "gearshape.2")
        XCTAssertEqual(metadata.order, 131)
        XCTAssertEqual(metadata.tableName, "Localizable")
    }

    @MainActor
    func testThemeContributionIsAvailable() {
        let contributions = MatrixThemePlugin.themeContributions(context: GitOKPluginContext())

        XCTAssertEqual(contributions.count, 1)
        XCTAssertEqual(contributions[0].id, "automation")
        XCTAssertEqual(contributions[0].displayName, "Matrix")
        XCTAssertEqual(contributions[0].compactName, "Matrix")
        XCTAssertEqual(contributions[0].iconName, "gearshape.2")
        XCTAssertEqual(contributions[0].editorThemeId, "automation")
        XCTAssertEqual(contributions[0].sortKey.pluginOrder, 131)
    }

    func testLocalizationCatalogIsPackaged() {
        let resourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        XCTAssertNotNil(resourceURL)
    }
}
