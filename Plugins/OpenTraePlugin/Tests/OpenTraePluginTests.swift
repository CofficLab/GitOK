import XCTest
@testable import OpenTraePlugin

final class OpenTraePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenTraePlugin.metadata

        XCTAssertEqual(metadata.id, "OpenTrae")
        XCTAssertEqual(metadata.iconName, "brain")
        XCTAssertEqual(metadata.order, 8404)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenTraePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(OpenTraePluginLocalization.string("Open Trae").isEmpty)
        XCTAssertFalse(OpenTraePluginLocalization.string("Open in Trae").isEmpty)
    }

    func testToolbarContributionIsAvailable() {
        XCTAssertNotNil(OpenTraePlugin.shared.toolBarTrailingView())
    }

    func testLauncherConfigurationIsStable() {
        let configuration = TraeProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.trae.app")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Trae.app"))
    }
}
