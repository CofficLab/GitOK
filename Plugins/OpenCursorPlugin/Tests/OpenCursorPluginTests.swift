import XCTest
import GitOKCoreKit
import SwiftUI
@testable import OpenCursorPlugin

// MARK: - Configuration Tests

final class CursorConfigurationTests: XCTestCase {

    func testDefaultConfigurationHasCorrectBundleIdentifier() {
        let config = CursorApplicationConfiguration()
        XCTAssertEqual(config.bundleIdentifier, "com.todesktop.230313mzl4w4u92")
    }

    func testDefaultConfigurationIncludesSystemApplicationsPath() {
        let config = CursorApplicationConfiguration()
        XCTAssertTrue(config.fallbackApplicationPaths.contains("/Applications/Cursor.app"))
    }

    func testDefaultConfigurationIncludesUserApplicationsPath() {
        let config = CursorApplicationConfiguration()
        let userAppPath = "\(NSHomeDirectory())/Applications/Cursor.app"
        XCTAssertTrue(config.fallbackApplicationPaths.contains(userAppPath))
    }

    func testCustomConfigurationPreservesValues() {
        let config = CursorApplicationConfiguration(
            bundleIdentifier: "com.test.app",
            fallbackApplicationPaths: ["/custom/path.app"]
        )
        XCTAssertEqual(config.bundleIdentifier, "com.test.app")
        XCTAssertEqual(config.fallbackApplicationPaths, ["/custom/path.app"])
    }

    func testConfigurationEquatableEquality() {
        let a = CursorApplicationConfiguration()
        let b = CursorApplicationConfiguration()
        XCTAssertEqual(a, b)
    }

    func testConfigurationEquatableInequality() {
        let a = CursorApplicationConfiguration()
        let b = CursorApplicationConfiguration(
            bundleIdentifier: "com.different.app",
            fallbackApplicationPaths: []
        )
        XCTAssertNotEqual(a, b)
    }

    func testConfigurationWithEmptyFallbackPaths() {
        let config = CursorApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: []
        )
        XCTAssertTrue(config.fallbackApplicationPaths.isEmpty)
    }

    func testConfigurationWithMultipleFallbackPaths() {
        let paths = ["/App1.app", "/App2.app", "/App3.app"]
        let config = CursorApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: paths
        )
        XCTAssertEqual(config.fallbackApplicationPaths.count, 3)
        XCTAssertEqual(config.fallbackApplicationPaths, paths)
    }
}

// MARK: - Launcher Tests

final class CursorLauncherTests: XCTestCase {

    func testLauncherConfigurationIsStable() {
        let configuration = CursorProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.todesktop.230313mzl4w4u92")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Cursor.app"))
    }

    func testApplicationURLReturnsNilWithEmptyConfiguration() {
        let config = CursorApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: []
        )
        let url = CursorProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }

    func testApplicationURLReturnsNilWhenFallbackPathDoesNotExist() {
        let config = CursorApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: ["/nonexistent/path/Cursor.app"]
        )
        let url = CursorProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }
}

// MARK: - Plugin Metadata Tests

final class OpenCursorPluginMetadataTests: XCTestCase {

    func testPluginMetadataIsStable() {
        let metadata = OpenCursorPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenCursor")
        XCTAssertEqual(metadata.iconName, "cursor.rays")
        XCTAssertEqual(metadata.order, 8401)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testPluginPolicyIsOptIn() {
        let metadata = OpenCursorPlugin.metadata
        XCTAssertEqual(metadata.policy, .optIn)
    }

    func testPluginShouldRegister() {
        XCTAssertTrue(OpenCursorPlugin.shouldRegister)
    }

    func testPluginPolicyAllowsUserToggle() {
        let metadata = OpenCursorPlugin.metadata
        XCTAssertTrue(metadata.allowUserToggle)
    }

    func testPluginPolicyDefaultDisabled() {
        let metadata = OpenCursorPlugin.metadata
        XCTAssertFalse(metadata.defaultEnabled)
    }

    func testPluginDisplayNameIsLocalized() {
        let metadata = OpenCursorPlugin.metadata
        XCTAssertFalse(metadata.displayName.isEmpty)
    }

    func testPluginDescriptionIsLocalized() {
        let metadata = OpenCursorPlugin.metadata
        XCTAssertFalse(metadata.description.isEmpty)
    }
}

// MARK: - Localization Tests

final class OpenCursorLocalizationTests: XCTestCase {

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(
            OpenCursorPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        )
    }

    func testLocalizedStringsAreNotEmpty() {
        XCTAssertFalse(OpenCursorPluginLocalization.string("Open Cursor").isEmpty)
        XCTAssertFalse(OpenCursorPluginLocalization.string("Open in Cursor").isEmpty)
        XCTAssertFalse(
            OpenCursorPluginLocalization.string("Open the current project folder in Cursor.").isEmpty
        )
    }

    func testLocalizationTableIsCorrect() {
        XCTAssertEqual(OpenCursorPluginLocalization.table, "Localizable")
    }

    func testUnknownKeyReturnsKeyItself() {
        let unknownKey = "com.cofficlab.gitok.nonexistent.key"
        let result = OpenCursorPluginLocalization.string(unknownKey)
        XCTAssertEqual(result, unknownKey)
    }
}

// MARK: - Plugin Toolbar Contribution Tests

final class OpenCursorToolbarTests: XCTestCase {

    @MainActor
    func testToolbarReturnsEmptyWhenNoProjectURL() {
        let context = GitOKPluginContext(projectURL: nil)
        let items = OpenCursorPlugin.toolbarTrailingItems(context: context)
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testToolbarReturnsItemWhenProjectURLExists() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenCursorPlugin.toolbarTrailingItems(context: context)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "OpenCursor")
        XCTAssertNotNil(items.first?.view)
    }

    @MainActor
    func testToolbarOtherSlotsAreEmpty() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))

        XCTAssertTrue(OpenCursorPlugin.toolbarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenCursorPlugin.statusBarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenCursorPlugin.statusBarCenterItems(context: context).isEmpty)
        XCTAssertTrue(OpenCursorPlugin.statusBarTrailingItems(context: context).isEmpty)
        XCTAssertTrue(OpenCursorPlugin.settingsPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenCursorPlugin.sidebarPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenCursorPlugin.onboardingPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenCursorPlugin.listPaneItems(context: context, tab: .git).isEmpty)
        XCTAssertTrue(OpenCursorPlugin.detailPaneItems(context: context, tab: .git).isEmpty)
    }

    @MainActor
    func testThemeContributionsIsEmpty() {
        let context = GitOKPluginContext()
        XCTAssertTrue(OpenCursorPlugin.themeContributions(context: context).isEmpty)
    }

    @MainActor
    func testRootOverlayReturnsNil() {
        let context = GitOKPluginContext()
        let result = OpenCursorPlugin.rootOverlay(context: context, content: AnyView(EmptyView()))
        XCTAssertNil(result)
    }
}
