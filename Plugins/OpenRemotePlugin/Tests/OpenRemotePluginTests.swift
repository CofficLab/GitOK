import XCTest
import GitOKCoreKit
import SwiftUI
@testable import OpenRemotePlugin

// MARK: - OpenRemoteURLProvider Tests

final class OpenRemoteURLProviderTests: XCTestCase {

    // MARK: webURL(forRemoteURL:) with HTTPS

    func testWebURLFromHTTPSRemote() {
        let url = OpenRemoteURLProvider.webURL(forRemoteURL: "https://github.com/owner/repo.git")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://github.com/owner/repo")
    }

    func testWebURLFromHTTPSRemoteWithoutGitSuffix() {
        let url = OpenRemoteURLProvider.webURL(forRemoteURL: "https://github.com/owner/repo")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://github.com/owner/repo")
    }

    // MARK: webURL(forRemoteURL:) with SSH

    func testWebURLFromSSHRemote() {
        let url = OpenRemoteURLProvider.webURL(forRemoteURL: "git@github.com:owner/repo.git")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://github.com/owner/repo")
    }

    func testWebURLFromSSHRemoteWithoutGitSuffix() {
        let url = OpenRemoteURLProvider.webURL(forRemoteURL: "git@github.com:owner/repo")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://github.com/owner/repo")
    }

    // MARK: webURL(forRemoteURL:) with nil

    func testWebURLReturnsNilForNilInput() {
        let url = OpenRemoteURLProvider.webURL(forRemoteURL: nil)
        XCTAssertNil(url)
    }

    // MARK: webURL(forRemoteURL:) with empty string

    func testWebURLReturnsNilForEmptyString() {
        let url = OpenRemoteURLProvider.webURL(forRemoteURL: "")
        XCTAssertNil(url)
    }

    // MARK: webURL(forRemoteURL:) with invalid URL

    func testWebURLReturnsNilForInvalidURL() {
        let url = OpenRemoteURLProvider.webURL(forRemoteURL: "not-a-valid-url")
        XCTAssertNil(url)
    }

    // MARK: Different platforms

    func testWebURLFromGitLabHTTPS() {
        let url = OpenRemoteURLProvider.webURL(forRemoteURL: "https://gitlab.com/owner/repo.git")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://gitlab.com/owner/repo")
    }

    func testWebURLFromBitbucketHTTPS() {
        let url = OpenRemoteURLProvider.webURL(forRemoteURL: "https://bitbucket.org/owner/repo.git")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://bitbucket.org/owner/repo")
    }

    // MARK: Nested paths

    func testWebURLFromNestedPath() {
        let url = OpenRemoteURLProvider.webURL(forRemoteURL: "https://github.com/org/subgroup/repo.git")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://github.com/org/subgroup/repo")
    }

    // MARK: webURL(for:) requires async

    func testWebURLForProjectRequiresGitRemote() async {
        // /tmp is not a git repo, so this should return nil
        let url = await OpenRemoteURLProvider.webURL(for: URL(fileURLWithPath: "/tmp"))
        XCTAssertNil(url)
    }
}

// MARK: - Plugin Metadata Tests

final class OpenRemotePluginMetadataTests: XCTestCase {

    func testPluginMetadataIsStable() {
        let metadata = OpenRemotePlugin.metadata

        XCTAssertEqual(metadata.id, "OpenRemote")
        XCTAssertEqual(metadata.iconName, "link")
        XCTAssertEqual(metadata.order, 8407)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testPluginPolicyIsOptIn() {
        let metadata = OpenRemotePlugin.metadata
        XCTAssertEqual(metadata.policy, .optIn)
    }

    func testPluginShouldRegister() {
        XCTAssertTrue(OpenRemotePlugin.shouldRegister)
    }

    func testPluginPolicyAllowsUserToggle() {
        let metadata = OpenRemotePlugin.metadata
        XCTAssertTrue(metadata.allowUserToggle)
    }

    func testPluginPolicyDefaultDisabled() {
        let metadata = OpenRemotePlugin.metadata
        XCTAssertFalse(metadata.defaultEnabled)
    }
}

// MARK: - Localization Tests

final class OpenRemoteLocalizationTests: XCTestCase {

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(
            OpenRemotePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        )
    }

    func testLocalizedStringsAreNotEmpty() {
        XCTAssertFalse(OpenRemotePluginLocalization.string("Open Remote").isEmpty)
        XCTAssertFalse(OpenRemotePluginLocalization.string("Open in Browser").isEmpty)
        XCTAssertFalse(
            OpenRemotePluginLocalization.string("Open the remote repository in the browser.").isEmpty
        )
    }

    func testLocalizationTableIsCorrect() {
        XCTAssertEqual(OpenRemotePluginLocalization.table, "Localizable")
    }

    func testUnknownKeyReturnsKeyItself() {
        let unknownKey = "com.cofficlab.gitok.nonexistent.key"
        let result = OpenRemotePluginLocalization.string(unknownKey)
        XCTAssertEqual(result, unknownKey)
    }
}

// MARK: - Plugin Toolbar Contribution Tests

final class OpenRemoteToolbarTests: XCTestCase {

    @MainActor
    func testToolbarReturnsEmptyWhenNoProjectURL() {
        let context = GitOKPluginContext(projectURL: nil)
        let items = OpenRemotePlugin.toolbarTrailingItems(context: context)
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testToolbarReturnsItemWhenProjectURLExists() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenRemotePlugin.toolbarTrailingItems(context: context)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "OpenRemote")
        XCTAssertNotNil(items.first?.view)
    }

    @MainActor
    func testToolbarOtherSlotsAreEmpty() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))

        XCTAssertTrue(OpenRemotePlugin.toolbarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenRemotePlugin.tabItems(context: context).isEmpty)
        XCTAssertTrue(OpenRemotePlugin.statusBarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenRemotePlugin.statusBarCenterItems(context: context).isEmpty)
        XCTAssertTrue(OpenRemotePlugin.statusBarTrailingItems(context: context).isEmpty)
        XCTAssertTrue(OpenRemotePlugin.settingsPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenRemotePlugin.sidebarPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenRemotePlugin.onboardingPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenRemotePlugin.listPaneItems(context: context, tab: "any").isEmpty)
        XCTAssertTrue(OpenRemotePlugin.detailPaneItems(context: context, tab: "any").isEmpty)
    }

    @MainActor
    func testThemeContributionsIsEmpty() {
        let context = GitOKPluginContext()
        XCTAssertTrue(OpenRemotePlugin.themeContributions(context: context).isEmpty)
    }

    @MainActor
    func testRootOverlayReturnsNil() {
        let context = GitOKPluginContext()
        let result = OpenRemotePlugin.rootOverlay(context: context, content: AnyView(EmptyView()))
        XCTAssertNil(result)
    }
}
