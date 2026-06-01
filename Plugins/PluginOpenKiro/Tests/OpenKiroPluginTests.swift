import XCTest
@testable import PluginOpenKiro

final class OpenKiroPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenKiroPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenKiro")
        XCTAssertEqual(metadata.iconName, "water.waves")
        XCTAssertEqual(metadata.order, 8405)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "OpenKiro")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginOpenKiroLocalization.bundle.url(forResource: "OpenKiro", withExtension: "xcstrings"))
        XCTAssertFalse(PluginOpenKiroLocalization.string("Open Kiro").isEmpty)
        XCTAssertFalse(PluginOpenKiroLocalization.string("Open in Kiro").isEmpty)
    }

    func testToolbarContributionIsAvailable() {
        XCTAssertNotNil(OpenKiroPlugin.shared.toolBarTrailingView())
    }

    func testLauncherConfigurationIsStable() {
        let configuration = KiroProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "dev.kiro.desktop")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Kiro.app"))
    }
}
