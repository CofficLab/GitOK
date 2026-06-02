import XCTest
@testable import OpenGitHubDesktopPlugin

final class OpenGitHubDesktopPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenGitHubDesktopPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenGitHubDesktop")
        XCTAssertEqual(metadata.iconName, "desktopcomputer")
        XCTAssertEqual(metadata.order, 8403)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenGitHubDesktopPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(OpenGitHubDesktopPluginLocalization.string("Open GitHub Desktop").isEmpty)
        XCTAssertFalse(OpenGitHubDesktopPluginLocalization.string("Open in GitHub Desktop").isEmpty)
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
