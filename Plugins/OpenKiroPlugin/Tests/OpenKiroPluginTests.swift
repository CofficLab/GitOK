import XCTest
@testable import OpenKiroPlugin

final class OpenKiroPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenKiroPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenKiro")
        XCTAssertEqual(metadata.iconName, "water.waves")
        XCTAssertEqual(metadata.order, 8405)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenKiroPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(OpenKiroPluginLocalization.string("Open Kiro").isEmpty)
        XCTAssertFalse(OpenKiroPluginLocalization.string("Open in Kiro").isEmpty)
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
