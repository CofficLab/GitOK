import XCTest
import GitOKCoreKit
import SwiftUI
@testable import OpenVSCodePlugin

// MARK: - Configuration Tests

final class VSCodeConfigurationTests: XCTestCase {

    func testDefaultConfigurationHasCorrectBundleIdentifier() {
        let config = VSCodeApplicationConfiguration()
        XCTAssertEqual(config.bundleIdentifier, "com.microsoft.VSCode")
    }

    func testDefaultConfigurationIncludesSystemApplicationsPath() {
        let config = VSCodeApplicationConfiguration()
        XCTAssertTrue(config.fallbackApplicationPaths.contains("/Applications/Visual Studio Code.app"))
    }

    func testDefaultConfigurationIncludesUserApplicationsPath() {
        let config = VSCodeApplicationConfiguration()
        let userAppPath = "\(NSHomeDirectory())/Applications/Visual Studio Code.app"
        XCTAssertTrue(config.fallbackApplicationPaths.contains(userAppPath))
    }

    func testCustomConfigurationPreservesValues() {
        let config = VSCodeApplicationConfiguration(
            bundleIdentifier: "com.test.app",
            fallbackApplicationPaths: ["/custom/path.app"]
        )
        XCTAssertEqual(config.bundleIdentifier, "com.test.app")
        XCTAssertEqual(config.fallbackApplicationPaths, ["/custom/path.app"])
    }

    func testConfigurationEquatableEquality() {
        let a = VSCodeApplicationConfiguration()
        let b = VSCodeApplicationConfiguration()
        XCTAssertEqual(a, b)
    }

    func testConfigurationEquatableInequality() {
        let a = VSCodeApplicationConfiguration()
        let b = VSCodeApplicationConfiguration(
            bundleIdentifier: "com.different.app",
            fallbackApplicationPaths: []
        )
        XCTAssertNotEqual(a, b)
    }

    func testConfigurationWithEmptyFallbackPaths() {
        let config = VSCodeApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: []
        )
        XCTAssertTrue(config.fallbackApplicationPaths.isEmpty)
    }

    func testConfigurationWithMultipleFallbackPaths() {
        let paths = ["/App1.app", "/App2.app", "/App3.app"]
        let config = VSCodeApplicationConfiguration(
            bundleIdentifier: "com.test",
            fallbackApplicationPaths: paths
        )
        XCTAssertEqual(config.fallbackApplicationPaths.count, 3)
        XCTAssertEqual(config.fallbackApplicationPaths, paths)
    }
}

// MARK: - Launcher Tests

final class VSCodeLauncherTests: XCTestCase {

    func testLauncherConfigurationIsStable() {
        let configuration = VSCodeProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.microsoft.VSCode")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/Visual Studio Code.app"))
    }

    func testApplicationURLReturnsNilWithEmptyConfiguration() {
        let config = VSCodeApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: []
        )
        let url = VSCodeProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }

    func testApplicationURLReturnsNilWhenFallbackPathDoesNotExist() {
        let config = VSCodeApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: ["/nonexistent/path/VSCode.app"]
        )
        let url = VSCodeProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }
}

// MARK: - Plugin Metadata Tests

final class OpenVSCodePluginMetadataTests: XCTestCase {

    func testPluginMetadataIsStable() {
        let metadata = OpenVSCodePlugin.metadata

        XCTAssertEqual(metadata.id, "OpenVSCode")
        XCTAssertEqual(metadata.iconName, "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(metadata.order, 8400)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testPluginPolicyIsOptIn() {
        let metadata = OpenVSCodePlugin.metadata
        XCTAssertEqual(metadata.policy, .optIn)
    }

    func testPluginShouldRegister() {
        XCTAssertTrue(OpenVSCodePlugin.shouldRegister)
    }

    func testPluginPolicyAllowsUserToggle() {
        let metadata = OpenVSCodePlugin.metadata
        XCTAssertTrue(metadata.allowUserToggle)
    }

    func testPluginPolicyDefaultDisabled() {
        let metadata = OpenVSCodePlugin.metadata
        XCTAssertFalse(metadata.defaultEnabled)
    }

    func testPluginDisplayNameIsLocalized() {
        let metadata = OpenVSCodePlugin.metadata
        XCTAssertFalse(metadata.displayName.isEmpty)
    }

    func testPluginDescriptionIsLocalized() {
        let metadata = OpenVSCodePlugin.metadata
        XCTAssertFalse(metadata.description.isEmpty)
    }
}

// MARK: - Localization Tests

final class OpenVSCodeLocalizationTests: XCTestCase {

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(
            OpenVSCodePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        )
    }

    func testLocalizedStringsAreNotEmpty() {
        XCTAssertFalse(OpenVSCodePluginLocalization.string("Open VS Code").isEmpty)
        XCTAssertFalse(OpenVSCodePluginLocalization.string("Open in VS Code").isEmpty)
        XCTAssertFalse(
            OpenVSCodePluginLocalization.string("Open the current project folder in VS Code.").isEmpty
        )
    }

    func testLocalizationTableIsCorrect() {
        XCTAssertEqual(OpenVSCodePluginLocalization.table, "Localizable")
    }

    func testUnknownKeyReturnsKeyItself() {
        let unknownKey = "com.cofficlab.gitok.nonexistent.key"
        let result = OpenVSCodePluginLocalization.string(unknownKey)
        XCTAssertEqual(result, unknownKey)
    }
}

// MARK: - Plugin Toolbar Contribution Tests

final class OpenVSCodeToolbarTests: XCTestCase {

    @MainActor
    func testToolbarReturnsEmptyWhenNoProjectURL() {
        let context = GitOKPluginContext(projectURL: nil)
        let items = OpenVSCodePlugin.toolbarTrailingItems(context: context)
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testToolbarReturnsItemWhenProjectURLExists() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenVSCodePlugin.toolbarTrailingItems(context: context)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "OpenVSCode")
        XCTAssertNotNil(items.first?.view)
    }

    @MainActor
    func testToolbarOtherSlotsAreEmpty() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))

        XCTAssertTrue(OpenVSCodePlugin.toolbarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenVSCodePlugin.tabItems(context: context).isEmpty)
        XCTAssertTrue(OpenVSCodePlugin.statusBarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenVSCodePlugin.statusBarCenterItems(context: context).isEmpty)
        XCTAssertTrue(OpenVSCodePlugin.statusBarTrailingItems(context: context).isEmpty)
        XCTAssertTrue(OpenVSCodePlugin.settingsPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenVSCodePlugin.sidebarPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenVSCodePlugin.onboardingPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenVSCodePlugin.listPaneItems(context: context, tab: "any").isEmpty)
        XCTAssertTrue(OpenVSCodePlugin.detailPaneItems(context: context, tab: "any").isEmpty)
    }

    @MainActor
    func testThemeContributionsIsEmpty() {
        let context = GitOKPluginContext()
        XCTAssertTrue(OpenVSCodePlugin.themeContributions(context: context).isEmpty)
    }

    @MainActor
    func testRootOverlayReturnsNil() {
        let context = GitOKPluginContext()
        let result = OpenVSCodePlugin.rootOverlay(context: context, content: AnyView(EmptyView()))
        XCTAssertNil(result)
    }
}
