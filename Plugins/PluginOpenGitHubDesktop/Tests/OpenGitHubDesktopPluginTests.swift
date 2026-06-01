import XCTest
@testable import PluginOpenGitHubDesktop

final class OpenGitHubDesktopPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenGitHubDesktopPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenGitHubDesktop")
        XCTAssertEqual(metadata.iconName, "desktopcomputer")
        XCTAssertEqual(metadata.order, 8403)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "OpenGitHubDesktop")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginOpenGitHubDesktopLocalization.bundle.url(forResource: "OpenGitHubDesktop", withExtension: "xcstrings"))
        XCTAssertFalse(PluginOpenGitHubDesktopLocalization.string("Open GitHub Desktop").isEmpty)
        XCTAssertFalse(PluginOpenGitHubDesktopLocalization.string("Open in GitHub Desktop").isEmpty)
    }

    func testToolbarContributionIsAvailable() {
        XCTAssertNotNil(OpenGitHubDesktopPlugin.shared.toolBarTrailingView())
    }

    func testLauncherConfigurationIsStable() {
        let configuration = GitHubDesktopProjectLauncher.configuration

        XCTAssertEqual(configuration.bundleIdentifier, "com.github.GitHubClient")
        XCTAssertTrue(configuration.fallbackApplicationPaths.contains("/Applications/GitHub Desktop.app"))
    }

    func testRepositoryURLIsEncoded() {
        let url = URL(fileURLWithPath: "/tmp/GitOK Demo")
        let repositoryURL = GitHubDesktopProjectLauncher.localRepositoryURL(for: url)

        XCTAssertEqual(repositoryURL?.scheme, "github-desktop")
        XCTAssertEqual(repositoryURL?.absoluteString, "github-desktop://openLocalRepo?path=/tmp/GitOK%20Demo")
    }
}
