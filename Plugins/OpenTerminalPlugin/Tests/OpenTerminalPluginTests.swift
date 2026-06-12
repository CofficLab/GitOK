import XCTest
import GitOKCoreKit
import SwiftUI
@testable import OpenTerminalPlugin

// MARK: - ExternalTerminal Tests

final class ExternalTerminalTests: XCTestCase {

    // MARK: CaseIterable

    func testAllCasesContainsExpectedTerminals() {
        let allCases = ExternalTerminal.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.terminal))
        XCTAssertTrue(allCases.contains(.iTerm))
        XCTAssertTrue(allCases.contains(.warp))
    }

    // MARK: RawValue

    func testTerminalRawValue() {
        XCTAssertEqual(ExternalTerminal.terminal.rawValue, "terminal")
    }

    func testItermRawValue() {
        XCTAssertEqual(ExternalTerminal.iTerm.rawValue, "iTerm")
    }

    func testWarpRawValue() {
        XCTAssertEqual(ExternalTerminal.warp.rawValue, "warp")
    }

    // MARK: Identifiable

    func testIdMatchesRawValue() {
        for terminal in ExternalTerminal.allCases {
            XCTAssertEqual(terminal.id, terminal.rawValue)
        }
    }

    // MARK: Init from RawValue

    func testInitFromRawValueTerminal() {
        XCTAssertEqual(ExternalTerminal(rawValue: "terminal"), .terminal)
    }

    func testInitFromRawValueIterm() {
        XCTAssertEqual(ExternalTerminal(rawValue: "iTerm"), .iTerm)
    }

    func testInitFromRawValueWarp() {
        XCTAssertEqual(ExternalTerminal(rawValue: "warp"), .warp)
    }

    func testInitFromRawValueInvalidReturnsNil() {
        XCTAssertNil(ExternalTerminal(rawValue: "nonexistent"))
    }

    // MARK: BundleIdentifier

    func testTerminalBundleIdentifier() {
        XCTAssertEqual(ExternalTerminal.terminal.bundleIdentifier, "com.apple.Terminal")
    }

    func testItermBundleIdentifier() {
        XCTAssertEqual(ExternalTerminal.iTerm.bundleIdentifier, "com.googlecode.iterm2")
    }

    func testWarpBundleIdentifier() {
        XCTAssertEqual(ExternalTerminal.warp.bundleIdentifier, "dev.warp.Warp-Stable")
    }

    // MARK: AppPaths

    func testTerminalAppPathsContainsSystemPath() {
        let paths = ExternalTerminal.terminal.appPaths
        XCTAssertTrue(paths.contains("/System/Applications/Utilities/Terminal.app"))
    }

    func testTerminalAppPathsContainsAlternativePath() {
        let paths = ExternalTerminal.terminal.appPaths
        XCTAssertTrue(paths.contains("/Applications/Utilities/Terminal.app"))
    }

    func testItermAppPathsContainsSystemPath() {
        let paths = ExternalTerminal.iTerm.appPaths
        XCTAssertTrue(paths.contains("/Applications/iTerm.app"))
    }

    func testItermAppPathsContainsAlternativePath() {
        let paths = ExternalTerminal.iTerm.appPaths
        XCTAssertTrue(paths.contains("/Applications/iTerm2.app"))
    }

    func testItermAppPathsContainsUserPath() {
        let paths = ExternalTerminal.iTerm.appPaths
        XCTAssertTrue(paths.contains(NSHomeDirectory() + "/Applications/iTerm.app"))
    }

    func testWarpAppPathsContainsSystemPath() {
        let paths = ExternalTerminal.warp.appPaths
        XCTAssertTrue(paths.contains("/Applications/Warp.app"))
    }

    func testWarpAppPathsContainsUserPath() {
        let paths = ExternalTerminal.warp.appPaths
        XCTAssertTrue(paths.contains(NSHomeDirectory() + "/Applications/Warp.app"))
    }

    func testAllAppPathsAreNonEmpty() {
        for terminal in ExternalTerminal.allCases {
            XCTAssertFalse(terminal.appPaths.isEmpty, "\(terminal.rawValue) should have at least one app path")
        }
    }

    // MARK: Sendable Conformance

    func testExternalTerminalIsSendable() {
        // Compile-time check: this assignment should compile without warnings
        let _: any Sendable = ExternalTerminal.terminal
        let _: any Sendable = ExternalTerminal.iTerm
        let _: any Sendable = ExternalTerminal.warp
    }
}

// MARK: - TerminalLauncher Tests

final class TerminalLauncherTests: XCTestCase {

    func testAppURLReturnsNilForNonexistentApp() {
        let url = TerminalLauncher.appURL(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            appPaths: []
        )
        XCTAssertNil(url)
    }

    func testAppURLReturnsNilWhenPathDoesNotExist() {
        let url = TerminalLauncher.appURL(
            bundleIdentifier: "com.nonexistent.app.that.does.not.exist",
            appPaths: ["/nonexistent/path/Terminal.app"]
        )
        XCTAssertNil(url)
    }

    func testResolvedTerminalReturnsDefaultWhenNoUserDefaultsSet() {
        let defaults = UserDefaults(suiteName: "com.gitok.test.terminal.\(UUID().uuidString)")!
        let result = TerminalLauncher.resolvedTerminal(defaults: defaults)
        // Should return terminal as a fallback since test env may not have any installed
        XCTAssertNotNil(result)
    }

    func testDefaultTerminalKeyIsStable() {
        XCTAssertEqual(TerminalLauncher.defaultTerminalKey, "ExternalTools.DefaultTerminal")
    }
}

// MARK: - Plugin Metadata Tests

final class OpenTerminalPluginMetadataTests: XCTestCase {

    func testPluginMetadataIsStable() {
        let metadata = OpenTerminalPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenTerminal")
        XCTAssertEqual(metadata.iconName, "terminal")
        XCTAssertEqual(metadata.order, 8310)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testPluginPolicyIsOptIn() {
        let metadata = OpenTerminalPlugin.metadata
        XCTAssertEqual(metadata.policy, .optIn)
    }

    func testPluginShouldRegister() {
        XCTAssertTrue(OpenTerminalPlugin.shouldRegister)
    }

    func testPluginPolicyAllowsUserToggle() {
        let metadata = OpenTerminalPlugin.metadata
        XCTAssertTrue(metadata.allowUserToggle)
    }

    func testPluginPolicyDefaultDisabled() {
        let metadata = OpenTerminalPlugin.metadata
        XCTAssertFalse(metadata.defaultEnabled)
    }
}

// MARK: - Localization Tests

final class OpenTerminalLocalizationTests: XCTestCase {

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(
            OpenTerminalPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        )
    }

    func testLocalizedStringsAreNotEmpty() {
        XCTAssertFalse(OpenTerminalPluginLocalization.string("Open Terminal").isEmpty)
        XCTAssertFalse(OpenTerminalPluginLocalization.string("Open in Terminal").isEmpty)
        XCTAssertFalse(
            OpenTerminalPluginLocalization.string("Open the current project folder in Terminal.").isEmpty
        )
    }

    func testLocalizationTableIsCorrect() {
        XCTAssertEqual(OpenTerminalPluginLocalization.table, "Localizable")
    }

    func testUnknownKeyReturnsKeyItself() {
        let unknownKey = "com.cofficlab.gitok.nonexistent.key"
        let result = OpenTerminalPluginLocalization.string(unknownKey)
        XCTAssertEqual(result, unknownKey)
    }
}

// MARK: - Plugin Toolbar Contribution Tests

final class OpenTerminalToolbarTests: XCTestCase {

    @MainActor
    func testToolbarReturnsEmptyWhenNoProjectURL() {
        let context = GitOKPluginContext(projectURL: nil)
        let items = OpenTerminalPlugin.toolbarTrailingItems(context: context)
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testToolbarReturnsItemWhenProjectURLExists() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenTerminalPlugin.toolbarTrailingItems(context: context)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "OpenTerminal")
        XCTAssertNotNil(items.first?.view)
    }

    @MainActor
    func testToolbarOtherSlotsAreEmpty() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))

        XCTAssertTrue(OpenTerminalPlugin.toolbarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenTerminalPlugin.tabItems(context: context).isEmpty)
        XCTAssertTrue(OpenTerminalPlugin.statusBarLeadingItems(context: context).isEmpty)
        XCTAssertTrue(OpenTerminalPlugin.statusBarCenterItems(context: context).isEmpty)
        XCTAssertTrue(OpenTerminalPlugin.statusBarTrailingItems(context: context).isEmpty)
        XCTAssertTrue(OpenTerminalPlugin.settingsPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenTerminalPlugin.sidebarPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenTerminalPlugin.onboardingPaneItems(context: context).isEmpty)
        XCTAssertTrue(OpenTerminalPlugin.listPaneItems(context: context, tab: "any").isEmpty)
        XCTAssertTrue(OpenTerminalPlugin.detailPaneItems(context: context, tab: "any").isEmpty)
    }

    @MainActor
    func testThemeContributionsIsEmpty() {
        let context = GitOKPluginContext()
        XCTAssertTrue(OpenTerminalPlugin.themeContributions(context: context).isEmpty)
    }

    @MainActor
    func testRootOverlayReturnsNil() {
        let context = GitOKPluginContext()
        let result = OpenTerminalPlugin.rootOverlay(context: context, content: AnyView(EmptyView()))
        XCTAssertNil(result)
    }
}
