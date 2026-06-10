import XCTest
import GitOKCoreKit
@testable import OpenVSCodePlugin

final class OpenVSCodePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenVSCodePlugin.metadata

        XCTAssertEqual(metadata.id, "OpenVSCode")
        XCTAssertEqual(metadata.iconName, "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(metadata.order, 8400)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenVSCodePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(OpenVSCodePluginLocalization.string("Open VS Code").isEmpty)
        XCTAssertFalse(OpenVSCodePluginLocalization.string("Open in VS Code").isEmpty)
    }

    @MainActor
    func testToolbarContributionMatchesApplicationAvailability() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenVSCodePlugin.toolbarTrailingItems(context: context)
        let view = items.first?.view

        if VSCodeProjectLauncher.isInstalled {
            XCTAssertNotNil(view)
        } else {
            XCTAssertNil(view)
        }
    }

    func testLauncherConfigurationIsStable() {
        let configuration = VSCodeProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.microsoft.VSCode")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Visual Studio Code.app"))
    }
}
