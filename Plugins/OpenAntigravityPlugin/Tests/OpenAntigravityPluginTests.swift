import XCTest
import GitOKCoreKit
@testable import OpenAntigravityPlugin

final class OpenAntigravityPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenAntigravityPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenAntigravity")
        XCTAssertEqual(metadata.iconName, "paperplane")
        XCTAssertEqual(metadata.order, 8406)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenAntigravityPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(OpenAntigravityPluginLocalization.string("Open Antigravity").isEmpty)
        XCTAssertFalse(OpenAntigravityPluginLocalization.string("Open in Antigravity").isEmpty)
    }

    @MainActor
    func testToolbarContributionMatchesApplicationAvailability() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenAntigravityPlugin.toolbarTrailingItems(context: context)
        let view = items.first?.view

        if AntigravityProjectLauncher.isInstalled {
            XCTAssertNotNil(view)
        } else {
            XCTAssertNil(view)
        }
    }

    func testLauncherConfigurationIsStable() {
        let configuration = AntigravityProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.google.antigravity")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Antigravity.app"))
    }
}
