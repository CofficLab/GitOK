import XCTest
@testable import PluginOpenXcode

final class OpenXcodePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenXcodePlugin.metadata

        XCTAssertEqual(metadata.id, "OpenXcode")
        XCTAssertEqual(metadata.iconName, "hammer")
        XCTAssertEqual(metadata.order, 8402)
        XCTAssertTrue(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "OpenXcode")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginOpenXcodeLocalization.bundle.url(forResource: "OpenXcode", withExtension: "xcstrings"))
        XCTAssertFalse(PluginOpenXcodeLocalization.string("Open Xcode").isEmpty)
        XCTAssertFalse(PluginOpenXcodeLocalization.string("Open in Xcode").isEmpty)
    }

    func testToolbarContributionIsAvailable() {
        XCTAssertNotNil(OpenXcodePlugin.shared.toolBarTrailingView())
    }

    func testLauncherConfigurationIsStable() {
        let configuration = XcodeProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.apple.dt.Xcode")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Xcode.app"))
    }
}
