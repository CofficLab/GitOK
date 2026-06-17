import XCTest
import GitOKCoreKit
import SwiftUI
@testable import OpenKiroPlugin

// MARK: - Configuration Tests

final class KiroConfigurationTests: XCTestCase {

    func testDefaultConfigurationHasCorrectBundleIdentifier() {
        let config = KiroApplicationConfiguration()
        XCTAssertEqual(config.bundleIdentifier, "dev.kiro.desktop")
    }

    func testDefaultConfigurationIncludesSystemApplicationsPath() {
        let config = KiroApplicationConfiguration()
        XCTAssertTrue(config.fallbackApplicationPaths.contains("/Applications/Kiro.app"))
    }

    func testDefaultConfigurationIncludesUserApplicationsPath() {
        let config = KiroApplicationConfiguration()
        let userAppPath = "\(NSHomeDirectory())/Applications/Kiro.app"
        XCTAssertTrue(config.fallbackApplicationPaths.contains(userAppPath))
    }

    func testCustomConfigurationPreservesValues() {
        let config = KiroApplicationConfiguration(
            bundleIdentifier: "com.test.app",
            fallbackApplicationPaths: ["/custom/path.app"]
        )
        XCTAssertEqual(config.bundleIdentifier, "com.test.app")
        XCTAssertEqual(config.fallbackApplicationPaths, ["/custom/path.app"])
    }

    func testConfigurationEquatableEquality() {
        let a = KiroApplicationConfiguration()
        let b = KiroApplicationConfiguration()
        XCTAssertEqual(a, b)
    }

    func testConfigurationEquatableInequality() {
        let a = KiroApplicationConfiguration()
        let b = KiroApplicationConfiguration(
            bundleIdentifier: "com.different.app",
            fallbackApplicationPaths: []
        )
        XCTAssertNotEqual(a, b)
    }

    func testConfigurationWithEmptyFallbackPaths() {
        let config = KiroApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: []
        )
        XCTAssertTrue(config.fallbackApplicationPaths.isEmpty)
    }

    func testConfigurationWithMultipleFallbackPaths() {
        let paths = ["/App1.app", "/App2.app", "/App3.app"]
        let config = KiroApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: paths
        )
        XCTAssertEqual(config.fallbackApplicationPaths.count, 3)
        XCTAssertEqual(config.fallbackApplicationPaths, paths)
    }
}

// MARK: - Launcher Tests

final class KiroLauncherTests: XCTestCase {

    func testLauncherConfigurationIsStable() {
        let configuration = KiroProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "dev.kiro.desktop")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Kiro.app"))
    }

    func testApplicationURLReturnsNilWithEmptyConfiguration() {
        let config = KiroApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: []
        )
        let url = KiroProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }

    func testApplicationURLReturnsNilWhenFallbackPathDoesNotExist() {
        let config = KiroApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: ["/nonexistent/path/Kiro.app"]
        )
        let url = KiroProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }
}

// MARK: - Plugin Metadata Tests

final class OpenKiroPluginMetadataTests: XCTestCase {

    func testPluginMetadataIsStable() {
        let metadata = OpenKiroPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenKiro")
        XCTAssertEqual(metadata.iconName, "water.waves")
        XCTAssertEqual(metadata.order, 8405)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testPluginPolicyIsOptIn() {
        let metadata = OpenKiroPlugin.metadata
        XCTAssertEqual(metadata.policy, .optIn)
    }

    func testPluginShouldRegister() {
        XCTAssertTrue(OpenKiroPlugin.shouldRegister)
    }

    func testPluginPolicyAllowsUserToggle() {
        let metadata = OpenKiroPlugin.metadata
        XCTAssertTrue(metadata.allowUserToggle)
    }

    func testPluginPolicyDefaultDisabled() {
        let metadata = OpenKiroPlugin.metadata
        XCTAssertFalse(metadata.defaultEnabled)
    }

    func testPluginDisplayNameIsLocalized() {
        let metadata = OpenKiroPlugin.metadata
        XCTAssertFalse(metadata.displayName.isEmpty)
    }

    func testPluginDescriptionIsLocalized() {
        let metadata = OpenKiroPlugin.metadata
        XCTAssertFalse(metadata.description.isEmpty)
    }
}

// MARK: - Localization Tests

final class OpenKiroLocalizationTests: XCTestCase {

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(
            OpenKiroPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        )
    }

    func testLocalizedStringsAreNotEmpty() {
        XCTAssertFalse(OpenKiroPluginLocalization.string("Open Kiro").isEmpty)
        XCTAssertFalse(OpenKiroPluginLocalization.string("Open in Kiro").isEmpty)
        XCTAssertFalse(
            OpenKiroPluginLocalization.string("Open the current project folder in Kiro.").isEmpty
        )
    }

    func testLocalizationTableIsCorrect() {
        XCTAssertEqual(OpenKiroPluginLocalization.table, "Localizable")
    }

    func testUnknownKeyReturnsKeyItself() {
        let unknownKey = "com.cofficlab.gitok.nonexistent.key"
        let result = OpenKiroPluginLocalization.string(unknownKey)
        XCTAssertEqual(result, unknownKey)
    }
}

// MARK: - Plugin Toolbar Contribution Tests

final class OpenKiroToolbarTests: XCTestCase {

    @MainActor
    func testToolbarReturnsEmptyWhenNoProjectURL() {
        let context = GitOKPluginContext(projectURL: nil)
        let items = OpenKiroPlugin.toolbarTrailingItems(context: context)
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testToolbarReturnsItemWhenProjectURLExists() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenKiroPlugin.toolbarTrailingItems(context: context)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "OpenKiro")
        XCTAssertNotNil(items.first?.view)
    }

    @MainActor
    func testToolbarOtherSlotsAreEmpty() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))

        XCTAssertTrue(OpenKiroPlugin.toolbarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenKiroPlugin.statusBarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenKiroPlugin.statusBarCenterItems(context: context).isEmpty)
        XCTAssertTrue(OpenKiroPlugin.statusBarTrailingItems(context: context).isEmpty)
        XCTAssertTrue(OpenKiroPlugin.settingsPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenKiroPlugin.sidebarPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenKiroPlugin.onboardingPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenKiroPlugin.listPaneItems(context: context, tab: .git).isEmpty)
        XCTAssertTrue(OpenKiroPlugin.detailPaneItems(context: context, tab: .git).isEmpty)
    }

    @MainActor
    func testThemeContributionsIsEmpty() {
        let context = GitOKPluginContext()
        XCTAssertTrue(OpenKiroPlugin.themeContributions(context: context).isEmpty)
    }

    @MainActor
    func testRootOverlayReturnsNil() {
        let context = GitOKPluginContext()
        let result = OpenKiroPlugin.rootOverlay(context: context, content: AnyView(EmptyView()))
        XCTAssertNil(result)
    }
}
