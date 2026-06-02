import XCTest
@testable import OpenVSCodePlugin

final class OpenVSCodePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenVSCodePlugin.metadata

        XCTAssertEqual(metadata.id, "OpenVSCode")
        XCTAssertEqual(metadata.iconName, "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(metadata.order, 8400)
        XCTAssertTrue(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "OpenVSCode")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenVSCodePluginLocalization.bundle.url(forResource: "OpenVSCode", withExtension: "xcstrings"))
        XCTAssertFalse(OpenVSCodePluginLocalization.string("Open VS Code").isEmpty)
        XCTAssertFalse(OpenVSCodePluginLocalization.string("Open in VS Code").isEmpty)
    }

    func testToolbarContributionIsAvailable() {
        XCTAssertNotNil(OpenVSCodePlugin.shared.toolBarTrailingView())
    }

    func testLauncherConfigurationIsStable() {
        let configuration = VSCodeProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.microsoft.VSCode")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Visual Studio Code.app"))
    }
}
