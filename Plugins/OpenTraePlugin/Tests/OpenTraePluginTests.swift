import XCTest
import GitOKCoreKit
import SwiftUI
@testable import OpenTraePlugin

// MARK: - Configuration Tests

final class TraeConfigurationTests: XCTestCase {

    func testDefaultConfigurationHasCorrectBundleIdentifier() {
        let config = TraeApplicationConfiguration()
        XCTAssertEqual(config.bundleIdentifier, "com.trae.app")
    }

    func testDefaultConfigurationIncludesSystemApplicationsPath() {
        let config = TraeApplicationConfiguration()
        XCTAssertTrue(config.fallbackApplicationPaths.contains("/Applications/Trae.app"))
    }

    func testDefaultConfigurationIncludesUserApplicationsPath() {
        let config = TraeApplicationConfiguration()
        let userAppPath = "\(NSHomeDirectory())/Applications/Trae.app"
        XCTAssertTrue(config.fallbackApplicationPaths.contains(userAppPath))
    }

    func testCustomConfigurationPreservesValues() {
        let config = TraeApplicationConfiguration(
            bundleIdentifier: "com.test.app",
            fallbackApplicationPaths: ["/custom/path.app"]
        )
        XCTAssertEqual(config.bundleIdentifier, "com.test.app")
        XCTAssertEqual(config.fallbackApplicationPaths, ["/custom/path.app"])
    }

    func testConfigurationEquatableEquality() {
        let a = TraeApplicationConfiguration()
        let b = TraeApplicationConfiguration()
        XCTAssertEqual(a, b)
    }

    func testConfigurationEquatableInequality() {
        let a = TraeApplicationConfiguration()
        let b = TraeApplicationConfiguration(
            bundleIdentifier: "com.different.app",
            fallbackApplicationPaths: []
        )
        XCTAssertNotEqual(a, b)
    }

    func testConfigurationWithEmptyFallbackPaths() {
        let config = TraeApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: []
        )
        XCTAssertTrue(config.fallbackApplicationPaths.isEmpty)
    }

    func testConfigurationWithMultipleFallbackPaths() {
        let paths = ["/App1.app", "/App2.app", "/App3.app"]
        let config = TraeApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: paths
        )
        XCTAssertEqual(config.fallbackApplicationPaths.count, 3)
        XCTAssertEqual(config.fallbackApplicationPaths, paths)
    }
}

// MARK: - Launcher Tests

final class TraeLauncherTests: XCTestCase {

    func testLauncherConfigurationIsStable() {
        let configuration = TraeProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.trae.app")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Trae.app"))
    }

    func testApplicationURLReturnsNilWithEmptyConfiguration() {
        // With empty fallback paths and a non-existent bundle ID, should return nil
        let config = TraeApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: []
        )
        let url = TraeProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }

    func testApplicationURLReturnsNilWhenFallbackPathDoesNotExist() {
        let config = TraeApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: ["/nonexistent/path/Trae.app"]
        )
        let url = TraeProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }

    func testIsInstalledMatchesApplicationURLPresence() {
        XCTAssertEqual(TraeProjectLauncher.isInstalled, TraeProjectLauncher.applicationURL() != nil)
    }
}

// MARK: - Plugin Metadata Tests

final class OpenTraePluginMetadataTests: XCTestCase {

    func testPluginMetadataIsStable() {
        let metadata = OpenTraePlugin.metadata

        XCTAssertEqual(metadata.id, "OpenTrae")
        XCTAssertEqual(metadata.iconName, "brain")
        XCTAssertEqual(metadata.order, 8404)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testPluginPolicyIsOptIn() {
        let metadata = OpenTraePlugin.metadata
        XCTAssertEqual(metadata.policy, .optIn)
    }

    func testPluginShouldRegister() {
        XCTAssertTrue(OpenTraePlugin.shouldRegister)
    }

    func testPluginPolicyAllowsUserToggle() {
        let metadata = OpenTraePlugin.metadata
        XCTAssertTrue(metadata.allowUserToggle)
    }

    func testPluginPolicyDefaultDisabled() {
        let metadata = OpenTraePlugin.metadata
        XCTAssertFalse(metadata.defaultEnabled)
    }

    func testPluginDisplayNameIsLocalized() {
        let metadata = OpenTraePlugin.metadata
        XCTAssertFalse(metadata.displayName.isEmpty)
    }

    func testPluginDescriptionIsLocalized() {
        let metadata = OpenTraePlugin.metadata
        XCTAssertFalse(metadata.description.isEmpty)
    }
}

// MARK: - Localization Tests

final class OpenTraeLocalizationTests: XCTestCase {

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(
            OpenTraePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        )
    }

    func testLocalizedStringsAreNotEmpty() {
        XCTAssertFalse(OpenTraePluginLocalization.string("Open Trae").isEmpty)
        XCTAssertFalse(OpenTraePluginLocalization.string("Open in Trae").isEmpty)
        XCTAssertFalse(
            OpenTraePluginLocalization.string("Open the current project folder in Trae.").isEmpty
        )
    }

    func testLocalizationTableIsCorrect() {
        XCTAssertEqual(OpenTraePluginLocalization.table, "Localizable")
    }

    func testUnknownKeyReturnsKeyItself() {
        let unknownKey = "com.cofficlab.gitok.nonexistent.key"
        let result = OpenTraePluginLocalization.string(unknownKey)
        XCTAssertEqual(result, unknownKey)
    }
}

// MARK: - Plugin Toolbar Contribution Tests

final class OpenTraeToolbarTests: XCTestCase {

    @MainActor
    func testToolbarReturnsEmptyWhenNoProjectURL() {
        let context = GitOKPluginContext(projectURL: nil)
        let items = OpenTraePlugin.toolbarTrailingItems(context: context)
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testToolbarRespectsTraeInstallationState() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenTraePlugin.toolbarTrailingItems(context: context)

        if TraeProjectLauncher.isInstalled {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.id, "OpenTrae")
            XCTAssertNotNil(items.first?.view)
        } else {
            XCTAssertTrue(items.isEmpty)
        }
    }

    @MainActor
    func testToolbarOtherSlotsAreEmpty() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))

        XCTAssertTrue(OpenTraePlugin.toolbarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenTraePlugin.statusBarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenTraePlugin.statusBarCenterItems(context: context).isEmpty)
        XCTAssertTrue(OpenTraePlugin.statusBarTrailingItems(context: context).isEmpty)
        XCTAssertTrue(OpenTraePlugin.settingsPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenTraePlugin.sidebarPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenTraePlugin.onboardingPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenTraePlugin.listPaneItems(context: context, tab: .git).isEmpty)
        XCTAssertTrue(OpenTraePlugin.detailPaneItems(context: context, tab: .git).isEmpty)
    }

    @MainActor
    func testThemeContributionsIsEmpty() {
        let context = GitOKPluginContext()
        XCTAssertTrue(OpenTraePlugin.themeContributions(context: context).isEmpty)
    }

    @MainActor
    func testRootOverlayReturnsNil() {
        let context = GitOKPluginContext()
        let result = OpenTraePlugin.rootOverlay(context: context, content: AnyView(EmptyView()))
        XCTAssertNil(result)
    }
}
