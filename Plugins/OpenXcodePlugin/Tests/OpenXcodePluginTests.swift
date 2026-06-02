import XCTest
@testable import OpenXcodePlugin

final class OpenXcodePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenXcodePlugin.metadata

        XCTAssertEqual(metadata.id, "OpenXcode")
        XCTAssertEqual(metadata.iconName, "hammer")
        XCTAssertEqual(metadata.order, 8402)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenXcodePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(OpenXcodePluginLocalization.string("Open Xcode").isEmpty)
        XCTAssertFalse(OpenXcodePluginLocalization.string("Open in Xcode").isEmpty)
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
