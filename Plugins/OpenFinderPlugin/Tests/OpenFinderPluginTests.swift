import XCTest
import GitOKCoreKit
import SwiftUI
@testable import OpenFinderPlugin

// MARK: - Plugin Metadata Tests

final class OpenFinderPluginMetadataTests: XCTestCase {

    func testPluginMetadataIsStable() {
        let metadata = OpenFinderPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenFinder")
        XCTAssertEqual(metadata.iconName, "folder")
        XCTAssertEqual(metadata.order, 8300)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testPluginPolicyIsOptIn() {
        let metadata = OpenFinderPlugin.metadata
        XCTAssertEqual(metadata.policy, .optIn)
    }

    func testPluginShouldRegister() {
        XCTAssertTrue(OpenFinderPlugin.shouldRegister)
    }

    func testPluginPolicyAllowsUserToggle() {
        let metadata = OpenFinderPlugin.metadata
        XCTAssertTrue(metadata.allowUserToggle)
    }

    func testPluginPolicyDefaultDisabled() {
        let metadata = OpenFinderPlugin.metadata
        XCTAssertFalse(metadata.defaultEnabled)
    }

    func testPluginDisplayNameIsLocalized() {
        let metadata = OpenFinderPlugin.metadata
        XCTAssertFalse(metadata.displayName.isEmpty)
    }

    func testPluginDescriptionIsLocalized() {
        let metadata = OpenFinderPlugin.metadata
        XCTAssertFalse(metadata.description.isEmpty)
    }
}

// MARK: - Localization Tests

final class OpenFinderLocalizationTests: XCTestCase {

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(
            OpenFinderPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        )
    }

    func testLocalizedStringsAreNotEmpty() {
        XCTAssertFalse(OpenFinderPluginLocalization.string("Open Finder").isEmpty)
        XCTAssertFalse(OpenFinderPluginLocalization.string("Open in Finder").isEmpty)
    }

    func testLocalizationTableIsCorrect() {
        XCTAssertEqual(OpenFinderPluginLocalization.table, "Localizable")
    }

    func testUnknownKeyReturnsKeyItself() {
        let unknownKey = "com.cofficlab.gitok.nonexistent.key"
        let result = OpenFinderPluginLocalization.string(unknownKey)
        XCTAssertEqual(result, unknownKey)
    }
}

// MARK: - Plugin Toolbar Contribution Tests

final class OpenFinderToolbarTests: XCTestCase {

    @MainActor
    func testToolbarContributionIsAvailable() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"))
        XCTAssertFalse(OpenFinderPlugin.toolbarTrailingItems(context: context).isEmpty)
    }

    @MainActor
    func testToolbarReturnsEmptyWhenNoProjectURL() {
        let context = GitOKPluginContext(projectURL: nil)
        let items = OpenFinderPlugin.toolbarTrailingItems(context: context)
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testToolbarReturnsItemWhenProjectURLExists() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenFinderPlugin.toolbarTrailingItems(context: context)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "OpenFinder")
        XCTAssertNotNil(items.first?.view)
    }

    @MainActor
    func testToolbarOtherSlotsAreEmpty() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))

        XCTAssertTrue(OpenFinderPlugin.toolbarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenFinderPlugin.statusBarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenFinderPlugin.statusBarCenterItems(context: context).isEmpty)
        XCTAssertTrue(OpenFinderPlugin.statusBarTrailingItems(context: context).isEmpty)
        XCTAssertTrue(OpenFinderPlugin.settingsPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenFinderPlugin.sidebarPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenFinderPlugin.onboardingPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenFinderPlugin.listPaneItems(context: context, tab: .git).isEmpty)
        XCTAssertTrue(OpenFinderPlugin.detailPaneItems(context: context, tab: .git).isEmpty)
    }

    @MainActor
    func testThemeContributionsIsEmpty() {
        let context = GitOKPluginContext()
        XCTAssertTrue(OpenFinderPlugin.themeContributions(context: context).isEmpty)
    }

    @MainActor
    func testRootOverlayReturnsNil() {
        let context = GitOKPluginContext()
        let result = OpenFinderPlugin.rootOverlay(context: context, content: AnyView(EmptyView()))
        XCTAssertNil(result)
    }
}
