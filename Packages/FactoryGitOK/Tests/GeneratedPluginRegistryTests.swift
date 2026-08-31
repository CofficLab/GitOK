import XCTest
@testable import FactoryGitOK

/// Architecture guard (Lumi FactoryCoreTests equivalent).
///
/// Pins the exact set of bundled plugins so additions/removals are conscious
/// registry decisions, and enforces the order-band convention documented in
/// docs/plugins/architecture.md.
@MainActor
final class GeneratedPluginRegistryTests: XCTestCase {
    func testRegistryContainsExactPluginSet() {
        let ids = Set(GeneratedPluginRegistry.plugins.map { $0.metadata.id })
        let expected: Set<String> = [
            // Core (0-99)
            "ProjectsPlugin",
            "OnboardingPlugin",
            "GitRepositorySettingsPlugin",
            "GitUserSettingsPlugin",
            "GitWatcherPlugin",
            "GitCleanStatusPlugin",
            "GitUnpushedStatusPlugin",
            "ProjectPickerPlugin",
            // Base services (100-199)
            "GitCommitStyleSettingsPlugin",
            "GitNetworkSettingsPlugin",
            "DiagnosticsSettingsPlugin",
            "AppearanceSettingsPlugin",
            "AboutSettingsPlugin",
            "SettingsButton",
            "ActivityStatusPlugin",
            // Git features (200-299)
            "GitWorkingStatePlugin",
            "GitCommitListPlugin",
            "GitDetailPlugin",
            "GitBranchPlugin",
            "GitAutoPushPlugin",
            "GitStashPlugin",
            "GitSubmodulePlugin",
            "GitConflictResolverPlugin",
            "GitMergePlugin",
            "GitRemoteRepositoryPlugin",
            "GitLFSPlugin",
            "GitignorePlugin",
            "ReadmePlugin",
            // Optional (300+)
            "SmartFilePlugin",
            "LicensePlugin",
            "ThemeStatusBarPlugin",
            "ThemeGitOKPlugin",
            "ThemeSpringPlugin",
            "ThemeAuroraPlugin",
            "ThemeMidnightPlugin",
            "ThemeEmberPlugin",
            "ThemeRiverPlugin",
            "ThemeNebulaPlugin",
            "ThemeHarborPlugin",
            "ThemeOrchardPlugin",
            "ThemeGlacierPlugin",
            "ThemeSummerPlugin",
            "ThemeMatrixPlugin",
            "ThemeMountainPlugin",
            "ThemeWinterPlugin",
            "ThemeGraphitePlugin",
            "ThemeDraculaPlugin",
            "ThemeOneDarkPlugin",
            "ThemeXcodeLightPlugin",
            "ThemeGitHubLightPlugin",
            "OpenFinder",
            "OpenTerminal",
            "OpenLumi",
            "OpenVSCode",
            "OpenCursor",
            "OpenXcode",
            "OpenGitHubDesktop",
            "OpenTrae",
            "OpenKiro",
            "OpenAntigravity",
            "OpenRemote",
        ]
        XCTAssertEqual(ids, expected)
    }

    func testPluginIdsAreUnique() {
        let ids = GeneratedPluginRegistry.plugins.map { $0.metadata.id }
        XCTAssertEqual(ids.count, Set(ids).count, "duplicate plugin ids in registry")
    }

    func testAllPluginOrdersFallIntoDefinedBands() {
        for plugin in GeneratedPluginRegistry.plugins {
            let order = plugin.metadata.order
            XCTAssertTrue(
                (0...1000).contains(order),
                "\(plugin.metadata.id) order \(order) outside defined bands (see docs/plugins/architecture.md)"
            )
        }
    }
}
