import XCTest
import GitOKCoreKit
import SwiftUI
@testable import OpenXcodePlugin

// MARK: - Configuration Tests

final class XcodeConfigurationTests: XCTestCase {

    func testDefaultConfigurationHasCorrectBundleIdentifier() {
        let config = XcodeApplicationConfiguration()
        XCTAssertEqual(config.bundleIdentifier, "com.apple.dt.Xcode")
    }

    func testDefaultConfigurationIncludesSystemApplicationsPath() {
        let config = XcodeApplicationConfiguration()
        XCTAssertTrue(config.fallbackApplicationPaths.contains("/Applications/Xcode.app"))
    }

    func testDefaultConfigurationIncludesUserApplicationsPath() {
        let config = XcodeApplicationConfiguration()
        let userAppPath = "\(NSHomeDirectory())/Applications/Xcode.app"
        XCTAssertTrue(config.fallbackApplicationPaths.contains(userAppPath))
    }

    func testCustomConfigurationPreservesValues() {
        let config = XcodeApplicationConfiguration(
            bundleIdentifier: "com.test.app",
            fallbackApplicationPaths: ["/custom/path.app"]
        )
        XCTAssertEqual(config.bundleIdentifier, "com.test.app")
        XCTAssertEqual(config.fallbackApplicationPaths, ["/custom/path.app"])
    }

    func testConfigurationEquatableEquality() {
        let a = XcodeApplicationConfiguration()
        let b = XcodeApplicationConfiguration()
        XCTAssertEqual(a, b)
    }

    func testConfigurationEquatableInequality() {
        let a = XcodeApplicationConfiguration()
        let b = XcodeApplicationConfiguration(
            bundleIdentifier: "com.different.app",
            fallbackApplicationPaths: []
        )
        XCTAssertNotEqual(a, b)
    }

    func testConfigurationWithEmptyFallbackPaths() {
        let config = XcodeApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: []
        )
        XCTAssertTrue(config.fallbackApplicationPaths.isEmpty)
    }

    func testConfigurationWithMultipleFallbackPaths() {
        let paths = ["/App1.app", "/App2.app", "/App3.app"]
        let config = XcodeApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: paths
        )
        XCTAssertEqual(config.fallbackApplicationPaths.count, 3)
        XCTAssertEqual(config.fallbackApplicationPaths, paths)
    }
}

// MARK: - Launcher Tests

final class XcodeLauncherTests: XCTestCase {

    func testLauncherConfigurationIsStable() {
        let configuration = XcodeProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.apple.dt.Xcode")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Xcode.app"))
    }

    func testApplicationURLReturnsNilWithEmptyConfiguration() {
        let config = XcodeApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: []
        )
        let url = XcodeProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }

    func testApplicationURLReturnsNilWhenFallbackPathDoesNotExist() {
        let config = XcodeApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: ["/nonexistent/path/Xcode.app"]
        )
        let url = XcodeProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }
}

// MARK: - Plugin Metadata Tests

final class OpenXcodePluginMetadataTests: XCTestCase {

    func testPluginMetadataIsStable() {
        let metadata = OpenXcodePlugin.metadata

        XCTAssertEqual(metadata.id, "OpenXcode")
        XCTAssertEqual(metadata.iconName, "hammer")
        XCTAssertEqual(metadata.order, 8402)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testPluginPolicyIsOptIn() {
        let metadata = OpenXcodePlugin.metadata
        XCTAssertEqual(metadata.policy, .optIn)
    }

    func testPluginShouldRegister() {
        XCTAssertTrue(OpenXcodePlugin.shouldRegister)
    }

    func testPluginPolicyAllowsUserToggle() {
        let metadata = OpenXcodePlugin.metadata
        XCTAssertTrue(metadata.allowUserToggle)
    }

    func testPluginPolicyDefaultDisabled() {
        let metadata = OpenXcodePlugin.metadata
        XCTAssertFalse(metadata.defaultEnabled)
    }

    func testPluginDisplayNameIsLocalized() {
        let metadata = OpenXcodePlugin.metadata
        XCTAssertFalse(metadata.displayName.isEmpty)
    }

    func testPluginDescriptionIsLocalized() {
        let metadata = OpenXcodePlugin.metadata
        XCTAssertFalse(metadata.description.isEmpty)
    }
}

// MARK: - Localization Tests

final class OpenXcodeLocalizationTests: XCTestCase {

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(
            OpenXcodePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        )
    }

    func testLocalizedStringsAreNotEmpty() {
        XCTAssertFalse(OpenXcodePluginLocalization.string("Open Xcode").isEmpty)
        XCTAssertFalse(OpenXcodePluginLocalization.string("Open in Xcode").isEmpty)
        XCTAssertFalse(
            OpenXcodePluginLocalization.string("Open the current project folder in Xcode.").isEmpty
        )
    }

    func testLocalizationTableIsCorrect() {
        XCTAssertEqual(OpenXcodePluginLocalization.table, "Localizable")
    }

    func testUnknownKeyReturnsKeyItself() {
        let unknownKey = "com.cofficlab.gitok.nonexistent.key"
        let result = OpenXcodePluginLocalization.string(unknownKey)
        XCTAssertEqual(result, unknownKey)
    }
}

// MARK: - Plugin Toolbar Contribution Tests

final class OpenXcodeToolbarTests: XCTestCase {

    @MainActor
    func testToolbarReturnsEmptyWhenNoProjectURL() {
        let context = GitOKPluginContext(projectURL: nil)
        let items = OpenXcodePlugin.toolbarTrailingItems(context: context)
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testToolbarReturnsItemWhenProjectURLExists() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenXcodePlugin.toolbarTrailingItems(context: context)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "OpenXcode")
        XCTAssertNotNil(items.first?.view)
    }

    @MainActor
    func testToolbarOtherSlotsAreEmpty() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))

        XCTAssertTrue(OpenXcodePlugin.toolbarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenXcodePlugin.statusBarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenXcodePlugin.statusBarCenterItems(context: context).isEmpty)
        XCTAssertTrue(OpenXcodePlugin.statusBarTrailingItems(context: context).isEmpty)
        XCTAssertTrue(OpenXcodePlugin.settingsPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenXcodePlugin.sidebarPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenXcodePlugin.onboardingPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenXcodePlugin.listPaneItems(context: context, tab: .git).isEmpty)
        XCTAssertTrue(OpenXcodePlugin.detailPaneItems(context: context, tab: .git).isEmpty)
    }

    @MainActor
    func testThemeContributionsIsEmpty() {
        let context = GitOKPluginContext()
        XCTAssertTrue(OpenXcodePlugin.themeContributions(context: context).isEmpty)
    }

    @MainActor
    func testRootOverlayReturnsNil() {
        let context = GitOKPluginContext()
        let result = OpenXcodePlugin.rootOverlay(context: context, content: AnyView(EmptyView()))
        XCTAssertNil(result)
    }
}
