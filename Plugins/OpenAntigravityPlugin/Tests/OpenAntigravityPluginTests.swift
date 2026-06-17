import XCTest
import GitOKCoreKit
import SwiftUI
@testable import OpenAntigravityPlugin

// MARK: - Mock App Locator

/// A fully controllable mock that lets tests dictate exactly which URLs exist
/// without touching NSWorkspace or the real file system.
private final class MockAppLocator: AppLocator, @unchecked Sendable {
    var bundleURL: URL?
    var existingPaths = Set<String>()

    func urlForApplication(withBundleIdentifier bundleID: String) -> URL? {
        bundleURL
    }

    func fileExists(atPath path: String) -> Bool {
        existingPaths.contains(path)
    }
}

// MARK: - Configuration Tests

final class AntigravityConfigurationTests: XCTestCase {

    func testDefaultConfigurationHasCorrectBundleIdentifier() {
        let config = AntigravityApplicationConfiguration()
        XCTAssertEqual(config.bundleIdentifier, "com.google.antigravity")
    }

    func testDefaultConfigurationIncludesSystemApplicationsPath() {
        let config = AntigravityApplicationConfiguration()
        XCTAssertTrue(config.fallbackApplicationPaths.contains("/Applications/Antigravity.app"))
    }

    func testDefaultConfigurationIncludesUserApplicationsPath() {
        let config = AntigravityApplicationConfiguration()
        let userAppPath = "\(NSHomeDirectory())/Applications/Antigravity.app"
        XCTAssertTrue(config.fallbackApplicationPaths.contains(userAppPath))
    }

    func testCustomConfigurationPreservesValues() {
        let config = AntigravityApplicationConfiguration(
            bundleIdentifier: "com.test.app",
            fallbackApplicationPaths: ["/custom/path.app"]
        )
        XCTAssertEqual(config.bundleIdentifier, "com.test.app")
        XCTAssertEqual(config.fallbackApplicationPaths, ["/custom/path.app"])
    }

    func testConfigurationEquatableEquality() {
        let a = AntigravityApplicationConfiguration()
        let b = AntigravityApplicationConfiguration()
        XCTAssertEqual(a, b)
    }

    func testConfigurationEquatableInequality() {
        let a = AntigravityApplicationConfiguration()
        let b = AntigravityApplicationConfiguration(
            bundleIdentifier: "com.different.app",
            fallbackApplicationPaths: []
        )
        XCTAssertNotEqual(a, b)
    }

    func testConfigurationWithEmptyFallbackPaths() {
        let config = AntigravityApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: []
        )
        XCTAssertTrue(config.fallbackApplicationPaths.isEmpty)
    }

    func testConfigurationWithMultipleFallbackPaths() {
        let paths = ["/App1.app", "/App2.app", "/App3.app"]
        let config = AntigravityApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: paths
        )
        XCTAssertEqual(config.fallbackApplicationPaths.count, 3)
        XCTAssertEqual(config.fallbackApplicationPaths, paths)
    }
}

// MARK: - Launcher applicationURL Tests

final class AntigravityLauncherTests: XCTestCase {

    // MARK: Bundle ID Resolution

    func testApplicationURLReturnsBundleIDURLWhenFound() {
        let mock = MockAppLocator()
        let expectedURL = URL(fileURLWithPath: "/Applications/Antigravity.app")
        mock.bundleURL = expectedURL

        let url = AntigravityProjectLauncher.applicationURL(
            configuration: AntigravityApplicationConfiguration(
                bundleIdentifier: "com.google.antigravity",
                fallbackApplicationPaths: []
            ),
            locator: mock
        )
        XCTAssertEqual(url, expectedURL)
    }

    func testApplicationURLPrefersBundleIDOverFallback() {
        let mock = MockAppLocator()
        let bundleURL = URL(fileURLWithPath: "/System/Applications/Antigravity.app")
        mock.bundleURL = bundleURL
        mock.existingPaths = ["/Applications/Antigravity.app"]

        let url = AntigravityProjectLauncher.applicationURL(
            configuration: AntigravityApplicationConfiguration(
                fallbackApplicationPaths: ["/Applications/Antigravity.app"]
            ),
            locator: mock
        )
        // Bundle ID should take priority
        XCTAssertEqual(url, bundleURL)
    }

    // MARK: Fallback Path Resolution

    func testApplicationURLReturnsFirstFallbackWhenBundleIDNotFound() {
        let mock = MockAppLocator()
        mock.bundleURL = nil
        mock.existingPaths = ["/Applications/Antigravity.app"]

        let url = AntigravityProjectLauncher.applicationURL(
            configuration: AntigravityApplicationConfiguration(
                fallbackApplicationPaths: ["/Applications/Antigravity.app"]
            ),
            locator: mock
        )
        XCTAssertEqual(url, URL(fileURLWithPath: "/Applications/Antigravity.app"))
    }

    func testApplicationURLReturnsSecondFallbackWhenFirstDoesNotExist() {
        let mock = MockAppLocator()
        mock.bundleURL = nil
        mock.existingPaths = ["\(NSHomeDirectory())/Applications/Antigravity.app"]

        let url = AntigravityProjectLauncher.applicationURL(
            configuration: AntigravityApplicationConfiguration(
                fallbackApplicationPaths: [
                    "/Applications/Antigravity.app",
                    "\(NSHomeDirectory())/Applications/Antigravity.app",
                ]
            ),
            locator: mock
        )
        XCTAssertEqual(url, URL(fileURLWithPath: "\(NSHomeDirectory())/Applications/Antigravity.app"))
    }

    // MARK: Not Found

    func testApplicationURLReturnsNilWhenNothingFound() {
        let mock = MockAppLocator()
        mock.bundleURL = nil
        mock.existingPaths = []

        let url = AntigravityProjectLauncher.applicationURL(
            configuration: AntigravityApplicationConfiguration(
                fallbackApplicationPaths: ["/Applications/Antigravity.app"]
            ),
            locator: mock
        )
        XCTAssertNil(url)
    }

    func testApplicationURLReturnsNilWithEmptyConfiguration() {
        let mock = MockAppLocator()
        mock.bundleURL = nil

        let url = AntigravityProjectLauncher.applicationURL(
            configuration: AntigravityApplicationConfiguration(
                fallbackApplicationPaths: []
            ),
            locator: mock
        )
        XCTAssertNil(url)
    }

    // MARK: isInstalled

    func testIsInstalledReturnsTrueWhenApplicationURLFound() {
        let mock = MockAppLocator()
        mock.bundleURL = URL(fileURLWithPath: "/Applications/Antigravity.app")

        let url = AntigravityProjectLauncher.applicationURL(
            configuration: AntigravityApplicationConfiguration(
                fallbackApplicationPaths: []
            ),
            locator: mock
        )
        XCTAssertNotNil(url)
    }

    func testIsInstalledReturnsFalseWhenApplicationURLNotFound() {
        let mock = MockAppLocator()
        mock.bundleURL = nil
        mock.existingPaths = []

        let url = AntigravityProjectLauncher.applicationURL(
            configuration: AntigravityApplicationConfiguration(
                fallbackApplicationPaths: ["/Applications/Antigravity.app"]
            ),
            locator: mock
        )
        XCTAssertNil(url)
    }

    // MARK: Default Configuration Stability

    func testDefaultLauncherConfigurationIsStable() {
        let config = AntigravityProjectLauncher.configuration
        XCTAssertEqual(config.bundleIdentifier, "com.google.antigravity")
        XCTAssertTrue(config.fallbackApplicationPaths.contains("/Applications/Antigravity.app"))
    }
}

// MARK: - Plugin Metadata Tests

final class OpenAntigravityPluginMetadataTests: XCTestCase {

    func testPluginMetadataIsStable() {
        let metadata = OpenAntigravityPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenAntigravity")
        XCTAssertEqual(metadata.iconName, "paperplane")
        XCTAssertEqual(metadata.order, 8406)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testPluginPolicyIsOptIn() {
        let metadata = OpenAntigravityPlugin.metadata
        XCTAssertEqual(metadata.policy, .optIn)
    }

    func testPluginShouldRegister() {
        XCTAssertTrue(OpenAntigravityPlugin.shouldRegister)
    }

    func testPluginPolicyAllowsUserToggle() {
        let metadata = OpenAntigravityPlugin.metadata
        XCTAssertTrue(metadata.allowUserToggle)
    }

    func testPluginPolicyDefaultDisabled() {
        let metadata = OpenAntigravityPlugin.metadata
        XCTAssertFalse(metadata.defaultEnabled)
    }

    func testPluginDisplayNameIsLocalized() {
        let metadata = OpenAntigravityPlugin.metadata
        XCTAssertFalse(metadata.displayName.isEmpty)
    }

    func testPluginDescriptionIsLocalized() {
        let metadata = OpenAntigravityPlugin.metadata
        XCTAssertFalse(metadata.description.isEmpty)
    }
}

// MARK: - Localization Tests

final class OpenAntigravityLocalizationTests: XCTestCase {

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(
            OpenAntigravityPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        )
    }

    func testLocalizedStringsAreNotEmpty() {
        XCTAssertFalse(OpenAntigravityPluginLocalization.string("Open Antigravity").isEmpty)
        XCTAssertFalse(OpenAntigravityPluginLocalization.string("Open in Antigravity").isEmpty)
        XCTAssertFalse(
            OpenAntigravityPluginLocalization.string("Open the current project folder in Antigravity.").isEmpty
        )
    }

    func testLocalizationTableIsCorrect() {
        XCTAssertEqual(OpenAntigravityPluginLocalization.table, "Localizable")
    }

    func testUnknownKeyReturnsKeyItself() {
        let unknownKey = "com.cofficlab.gitok.nonexistent.key"
        let result = OpenAntigravityPluginLocalization.string(unknownKey)
        XCTAssertEqual(result, unknownKey)
    }
}

// MARK: - Plugin Toolbar Contribution Tests

final class OpenAntigravityToolbarTests: XCTestCase {

    @MainActor
    func testToolbarReturnsEmptyWhenNoProjectURL() {
        let context = GitOKPluginContext(projectURL: nil)
        let items = OpenAntigravityPlugin.toolbarTrailingItems(context: context)
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testToolbarReturnsItemWhenProjectURLExists() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenAntigravityPlugin.toolbarTrailingItems(context: context)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "OpenAntigravity")
        XCTAssertNotNil(items.first?.view)
    }

    @MainActor
    func testToolbarOtherSlotsAreEmpty() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))

        XCTAssertTrue(OpenAntigravityPlugin.toolbarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenAntigravityPlugin.statusBarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenAntigravityPlugin.statusBarCenterItems(context: context).isEmpty)
        XCTAssertTrue(OpenAntigravityPlugin.statusBarTrailingItems(context: context).isEmpty)
        XCTAssertTrue(OpenAntigravityPlugin.settingsPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenAntigravityPlugin.sidebarPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenAntigravityPlugin.onboardingPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenAntigravityPlugin.listPaneItems(context: context, tab: .git).isEmpty)
        XCTAssertTrue(OpenAntigravityPlugin.detailPaneItems(context: context, tab: .git).isEmpty)
    }

    @MainActor
    func testThemeContributionsIsEmpty() {
        let context = GitOKPluginContext()
        XCTAssertTrue(OpenAntigravityPlugin.themeContributions(context: context).isEmpty)
    }

    @MainActor
    func testRootOverlayReturnsNil() {
        let context = GitOKPluginContext()
        let result = OpenAntigravityPlugin.rootOverlay(context: context, content: AnyView(EmptyView()))
        XCTAssertNil(result)
    }
}

// MARK: - System App Locator Tests

final class SystemAppLocatorTests: XCTestCase {

    func testSystemAppLocatorInitializesWithoutError() {
        _ = SystemAppLocator()
    }

    func testSystemAppLocatorFileExistsReturnsBool() {
        let locator = SystemAppLocator()
        // /tmp always exists on macOS
        XCTAssertTrue(locator.fileExists(atPath: "/tmp"))
        XCTAssertFalse(locator.fileExists(atPath: "/nonexistent/path/that/should/not/exist"))
    }
}
