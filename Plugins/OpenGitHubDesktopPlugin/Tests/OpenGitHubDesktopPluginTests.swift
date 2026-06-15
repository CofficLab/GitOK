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

private final class MockGitHubDesktopWorkspace: GitHubDesktopWorkspace, @unchecked Sendable {
    private(set) var openCallCount = 0
    private(set) var openedProjectURL: URL?
    private(set) var openedApplicationURL: URL?

    func openProject(_ projectURL: URL, withApplicationAt appURL: URL) {
        openCallCount += 1
        openedProjectURL = projectURL
        openedApplicationURL = appURL
    }
}

final class GitHubDesktopLauncherTests: XCTestCase {

    private let configuration = GitHubDesktopApplicationConfiguration(
        bundleIdentifier: "com.github.GitHubClient",
        fallbackApplicationPaths: []
    )

    override func tearDown() {
        GitHubDesktopProjectLauncher.locator = SystemAppLocator()
        GitHubDesktopProjectLauncher.workspace = SystemGitHubDesktopWorkspace()
        super.tearDown()
    }

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

    func testIsInstalledMatchesApplicationURLPresence() {
        XCTAssertEqual(GitHubDesktopProjectLauncher.isInstalled, GitHubDesktopProjectLauncher.applicationURL() != nil)
    }

    func testApplicationURLReturnsBundleIDURLWhenFound() {
        let mock = MockAppLocator()
        let expectedURL = URL(fileURLWithPath: "/Applications/GitHub Desktop.app")
        mock.bundleURL = expectedURL

        let url = GitHubDesktopProjectLauncher.applicationURL(
            configuration: configuration,
            locator: mock
        )

        XCTAssertEqual(url, expectedURL)
    }

    @MainActor
    func testOpenUsesInstalledApplicationWithProjectFolderURL() {
        let mockLocator = MockAppLocator()
        let mockWorkspace = MockGitHubDesktopWorkspace()
        let appURL = URL(fileURLWithPath: "/Applications/GitHub Desktop.app")
        let projectURL = URL(fileURLWithPath: "/Users/dev/My Project")
        mockLocator.bundleURL = appURL

        GitHubDesktopProjectLauncher.open(
            projectURL,
            configuration: configuration,
            locator: mockLocator,
            workspace: mockWorkspace
        )

        XCTAssertEqual(mockWorkspace.openCallCount, 1)
        XCTAssertEqual(mockWorkspace.openedProjectURL, projectURL)
        XCTAssertEqual(mockWorkspace.openedApplicationURL, appURL)
        XCTAssertEqual(mockWorkspace.openedProjectURL?.scheme, "file")
        XCTAssertNotEqual(mockWorkspace.openedProjectURL?.scheme, "github-desktop")
    }

    @MainActor
    func testOpenDoesNothingWhenApplicationIsNotInstalled() {
        let mockLocator = MockAppLocator()
        let mockWorkspace = MockGitHubDesktopWorkspace()
        let projectURL = URL(fileURLWithPath: "/Users/dev/MyProject")

        GitHubDesktopProjectLauncher.open(
            projectURL,
            configuration: configuration,
            locator: mockLocator,
            workspace: mockWorkspace
        )

        XCTAssertEqual(mockWorkspace.openCallCount, 0)
        XCTAssertNil(mockWorkspace.openedProjectURL)
        XCTAssertNil(mockWorkspace.openedApplicationURL)
    }

    @MainActor
    func testOpenDoesNotUseGitHubDesktopURLScheme() {
        let mockLocator = MockAppLocator()
        let mockWorkspace = MockGitHubDesktopWorkspace()
        let appURL = URL(fileURLWithPath: "/Applications/GitHub Desktop.app")
        let projectURL = URL(fileURLWithPath: "/Users/colorfy/Code/CofficLab/GitOK")
        mockLocator.bundleURL = appURL

        GitHubDesktopProjectLauncher.open(
            projectURL,
            configuration: configuration,
            locator: mockLocator,
            workspace: mockWorkspace
        )

        XCTAssertTrue(mockWorkspace.openedProjectURL?.isFileURL == true)
        XCTAssertFalse(mockWorkspace.openedProjectURL?.absoluteString.contains("github-desktop://") ?? true)
        XCTAssertFalse(mockWorkspace.openedProjectURL?.absoluteString.contains("openLocalRepo") ?? true)
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
    func testToolbarRespectsGitHubDesktopInstallationState() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenGitHubDesktopPlugin.toolbarTrailingItems(context: context)

        if GitHubDesktopProjectLauncher.isInstalled {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.id, "OpenGitHubDesktop")
            XCTAssertNotNil(items.first?.view)
        } else {
            XCTAssertTrue(items.isEmpty)
        }
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
