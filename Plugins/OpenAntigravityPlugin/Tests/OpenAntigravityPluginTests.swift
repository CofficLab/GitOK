import XCTest
@testable import OpenAntigravityPlugin

final class OpenAntigravityPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenAntigravityPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenAntigravity")
        XCTAssertEqual(metadata.iconName, "paperplane")
        XCTAssertEqual(metadata.order, 8406)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "OpenAntigravity")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenAntigravityPluginLocalization.bundle.url(forResource: "OpenAntigravity", withExtension: "xcstrings"))
        XCTAssertFalse(OpenAntigravityPluginLocalization.string("Open Antigravity").isEmpty)
        XCTAssertFalse(OpenAntigravityPluginLocalization.string("Open in Antigravity").isEmpty)
    }

    func testToolbarContributionIsAvailable() {
        XCTAssertNotNil(OpenAntigravityPlugin.shared.toolBarTrailingView())
    }

    func testLauncherConfigurationIsStable() {
        let configuration = AntigravityProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.google.antigravity")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Antigravity.app"))
    }
}
