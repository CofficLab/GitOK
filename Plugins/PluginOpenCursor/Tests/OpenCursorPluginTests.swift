import XCTest
@testable import PluginOpenCursor

final class OpenCursorPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenCursorPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenCursor")
        XCTAssertEqual(metadata.iconName, "cursor.rays")
        XCTAssertEqual(metadata.order, 8401)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "OpenCursor")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginOpenCursorLocalization.bundle.url(forResource: "OpenCursor", withExtension: "xcstrings"))
        XCTAssertFalse(PluginOpenCursorLocalization.string("Open Cursor").isEmpty)
        XCTAssertFalse(PluginOpenCursorLocalization.string("Open in Cursor").isEmpty)
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
