import XCTest
import GitOKCoreKit
import SwiftUI
@testable import OpenGitHubDesktopPlugin

// MARK: - Configuration Tests

final class GitHubDesktopConfigurationTests: XCTestCase {

    func testDefaultConfigurationHasCorrectBundleIdentifier() {
        let config = GitHubDesktopApplicationConfiguration()
        XCTAssertEqual(config.bundleIdentifier, "com.github.GitHubClient")
    }

    func testDefaultConfigurationIncludesSystemApplicationsPath() {
        let config = GitHubDesktopApplicationConfiguration()
        XCTAssertTrue(config.fallbackApplicationPaths.contains("/Applications/GitHub Desktop.app"))
    }

    func testDefaultConfigurationIncludesUserApplicationsPath() {
        let config = GitHubDesktopApplicationConfiguration()
        let userAppPath = "\(NSHomeDirectory())/Applications/GitHub Desktop.app"
        XCTAssertTrue(config.fallbackApplicationPaths.contains(userAppPath))
    }

    func testCustomConfigurationPreservesValues() {
        let config = GitHubDesktopApplicationConfiguration(
            bundleIdentifier: "com.test.app",
            fallbackApplicationPaths: ["/custom/path.app"]
        )
        XCTAssertEqual(config.bundleIdentifier, "com.test.app")
        XCTAssertEqual(config.fallbackApplicationPaths, ["/custom/path.app"])
    }

    func testConfigurationEquatableEquality() {
        let a = GitHubDesktopApplicationConfiguration()
        let b = GitHubDesktopApplicationConfiguration()
        XCTAssertEqual(a, b)
    }

    func testConfigurationEquatableInequality() {
        let a = GitHubDesktopApplicationConfiguration()
        let b = GitHubDesktopApplicationConfiguration(
            bundleIdentifier: "com.different.app",
            fallbackApplicationPaths: []
        )
        XCTAssertNotEqual(a, b)
    }
}

// MARK: - Launcher Tests

final class GitHubDesktopLauncherTests: XCTestCase {

    func testLauncherConfigurationIsStable() {
        let configuration = GitHubDesktopProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.github.GitHubClient")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/GitHub Desktop.app"))
    }

    func testApplicationURLReturnsNilWithEmptyConfiguration() {
        let config = GitHubDesktopApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: []
        )
        let url = GitHubDesktopProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }

    func testApplicationURLReturnsNilWhenFallbackPathDoesNotExist() {
        let config = GitHubDesktopApplicationConfiguration(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            fallbackApplicationPaths: ["/nonexistent/path/GitHub Desktop.app"]
        )
        let url = GitHubDesktopProjectLauncher.applicationURL(configuration: config)
        XCTAssertNil(url)
    }

    // MARK: localRepositoryURL Tests

    func testLocalRepositoryURLGeneratesCorrectScheme() {
        let projectURL = URL(fileURLWithPath: "/Users/dev/MyProject")
        let result = GitHubDesktopProjectLauncher.localRepositoryURL(for: projectURL)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.scheme, "github-desktop")
        XCTAssertEqual(result?.host, "openLocalRepo")
    }

    func testLocalRepositoryURLContainsPath() {
        let projectURL = URL(fileURLWithPath: "/Users/dev/MyProject")
        let result = GitHubDesktopProjectLauncher.localRepositoryURL(for: projectURL)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.absoluteString.contains("path=") ?? false)
    }

    func testLocalRepositoryURLEncodesSpaces() {
        let projectURL = URL(fileURLWithPath: "/Users/dev/My Project")
        let result = GitHubDesktopProjectLauncher.localRepositoryURL(for: projectURL)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.absoluteString.contains("My%20Project") ?? false)
    }

    func testLocalRepositoryURLAllowsAtCharacter() {
        // `@` is in the URLQueryAllowed character set and is not percent-encoded
        let projectURL = URL(fileURLWithPath: "/Users/dev/@special/project")
        let result = GitHubDesktopProjectLauncher.localRepositoryURL(for: projectURL)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.absoluteString.contains("@special") ?? false)
    }

    func testLocalRepositoryURLWithSimplePath() {
        let projectURL = URL(fileURLWithPath: "/tmp")
        let result = GitHubDesktopProjectLauncher.localRepositoryURL(for: projectURL)

        XCTAssertNotNil(result)
        let expected = "github-desktop://openLocalRepo?path=/tmp"
        XCTAssertEqual(result?.absoluteString, expected)
    }

    func testLocalRepositoryURLWithDeepPath() {
        let projectURL = URL(fileURLWithPath: "/Users/dev/projects/ios/MyApp")
        let result = GitHubDesktopProjectLauncher.localRepositoryURL(for: projectURL)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.absoluteString.contains("path=") ?? false)
        XCTAssertTrue(result?.absoluteString.contains("MyApp") ?? false)
    }
}

// MARK: - Plugin Metadata Tests

final class OpenGitHubDesktopPluginMetadataTests: XCTestCase {

    func testPluginMetadataIsStable() {
        let metadata = OpenGitHubDesktopPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenGitHubDesktop")
        XCTAssertEqual(metadata.iconName, "desktopcomputer")
        XCTAssertEqual(metadata.order, 8403)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testPluginPolicyIsOptIn() {
        let metadata = OpenGitHubDesktopPlugin.metadata
        XCTAssertEqual(metadata.policy, .optIn)
    }

    func testPluginShouldRegister() {
        XCTAssertTrue(OpenGitHubDesktopPlugin.shouldRegister)
    }

    func testPluginPolicyAllowsUserToggle() {
        let metadata = OpenGitHubDesktopPlugin.metadata
        XCTAssertTrue(metadata.allowUserToggle)
    }

    func testPluginPolicyDefaultDisabled() {
        let metadata = OpenGitHubDesktopPlugin.metadata
        XCTAssertFalse(metadata.defaultEnabled)
    }
}

// MARK: - Localization Tests

final class OpenGitHubDesktopLocalizationTests: XCTestCase {

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(
            OpenGitHubDesktopPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        )
    }

    func testLocalizedStringsAreNotEmpty() {
        XCTAssertFalse(OpenGitHubDesktopPluginLocalization.string("Open GitHub Desktop").isEmpty)
        XCTAssertFalse(OpenGitHubDesktopPluginLocalization.string("Open in GitHub Desktop").isEmpty)
        XCTAssertFalse(
            OpenGitHubDesktopPluginLocalization.string("Open the current project folder in GitHub Desktop.").isEmpty
        )
    }

    func testLocalizationTableIsCorrect() {
        XCTAssertEqual(OpenGitHubDesktopPluginLocalization.table, "Localizable")
    }

    func testUnknownKeyReturnsKeyItself() {
        let unknownKey = "com.cofficlab.gitok.nonexistent.key"
        let result = OpenGitHubDesktopPluginLocalization.string(unknownKey)
        XCTAssertEqual(result, unknownKey)
    }
}

// MARK: - Plugin Toolbar Contribution Tests

final class OpenGitHubDesktopToolbarTests: XCTestCase {

    @MainActor
    func testToolbarReturnsEmptyWhenNoProjectURL() {
        let context = GitOKPluginContext(projectURL: nil)
        let items = OpenGitHubDesktopPlugin.toolbarTrailingItems(context: context)
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testToolbarReturnsItemWhenProjectURLExists() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenGitHubDesktopPlugin.toolbarTrailingItems(context: context)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "OpenGitHubDesktop")
        XCTAssertNotNil(items.first?.view)
    }

    @MainActor
    func testToolbarOtherSlotsAreEmpty() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))

        XCTAssertTrue(OpenGitHubDesktopPlugin.toolbarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenGitHubDesktopPlugin.tabItems(context: context).isEmpty)
        XCTAssertTrue(OpenGitHubDesktopPlugin.statusBarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenGitHubDesktopPlugin.statusBarCenterItems(context: context).isEmpty)
        XCTAssertTrue(OpenGitHubDesktopPlugin.statusBarTrailingItems(context: context).isEmpty)
        XCTAssertTrue(OpenGitHubDesktopPlugin.settingsPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenGitHubDesktopPlugin.sidebarPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenGitHubDesktopPlugin.onboardingPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenGitHubDesktopPlugin.listPaneItems(context: context, tab: "any").isEmpty)
        XCTAssertTrue(OpenGitHubDesktopPlugin.detailPaneItems(context: context, tab: "any").isEmpty)
    }

    @MainActor
    func testThemeContributionsIsEmpty() {
        let context = GitOKPluginContext()
        XCTAssertTrue(OpenGitHubDesktopPlugin.themeContributions(context: context).isEmpty)
    }

    @MainActor
    func testRootOverlayReturnsNil() {
        let context = GitOKPluginContext()
        let result = OpenGitHubDesktopPlugin.rootOverlay(context: context, content: AnyView(EmptyView()))
        XCTAssertNil(result)
    }
}
