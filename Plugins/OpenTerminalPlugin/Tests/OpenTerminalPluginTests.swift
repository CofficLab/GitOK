import XCTest
import GitOKCoreKit
@testable import OpenTerminalPlugin

final class OpenTerminalPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenTerminalPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenTerminal")
        XCTAssertEqual(metadata.iconName, "terminal")
        XCTAssertEqual(metadata.order, 8310)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenTerminalPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(OpenTerminalPluginLocalization.string("Open Terminal").isEmpty)
        XCTAssertFalse(OpenTerminalPluginLocalization.string("Open in Terminal").isEmpty)
    }

    @MainActor
    func testToolbarContributionMatchesApplicationAvailability() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenTerminalPlugin.toolbarTrailingItems(context: context)
        let view = items.first?.view

        if TerminalLauncher.hasInstalledTerminal {
            XCTAssertNotNil(view)
        } else {
            XCTAssertNil(view)
        }
    }

    func testTerminalUserDefaultsKeyMatchesAppSetting() {
        XCTAssertEqual(TerminalLauncher.defaultTerminalKey, "ExternalTools.DefaultTerminal")
    }

    func testExternalTerminalBundleIdentifiersAreStable() {
        XCTAssertEqual(ExternalTerminal.terminal.bundleIdentifier, "com.apple.Terminal")
        XCTAssertEqual(ExternalTerminal.iTerm.bundleIdentifier, "com.googlecode.iterm2")
        XCTAssertEqual(ExternalTerminal.warp.bundleIdentifier, "dev.warp.Warp-Stable")
    }
}
