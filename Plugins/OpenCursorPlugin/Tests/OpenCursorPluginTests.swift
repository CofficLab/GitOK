import XCTest
@testable import OpenCursorPlugin

final class OpenCursorPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenCursorPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenCursor")
        XCTAssertEqual(metadata.iconName, "cursor.rays")
        XCTAssertEqual(metadata.order, 8401)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenCursorPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(OpenCursorPluginLocalization.string("Open Cursor").isEmpty)
        XCTAssertFalse(OpenCursorPluginLocalization.string("Open in Cursor").isEmpty)
    }

    func testToolbarContributionIsAvailable() {
        XCTAssertNotNil(OpenCursorPlugin.shared.toolBarTrailingView())
    }

    func testLauncherConfigurationIsStable() {
        let configuration = CursorProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.todesktop.230313mzl4w4u92")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Cursor.app"))
    }
}
