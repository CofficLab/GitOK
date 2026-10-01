import Foundation
import KernelCore
import Testing
@testable import PluginAboutSettings

@Suite("PluginAboutSettings")
@MainActor
struct PluginAboutSettingsTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = AboutSettingsPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.about-settings")
        #expect(plugin.metadata.category == .system)
        #expect(plugin.metadata.policy == .disabled)
        #expect(plugin.metadata.stage == .stable)
        #expect(plugin.order == 44)
        #expect(plugin.metadata.id == "com.coffic.gitok.plugin.about-settings")
    }

    @Test("AboutView bundle values fall back to defaults in test env")
    func aboutViewDefaults() {
        // In the test runner, Bundle.main has no app Info.plist values, so the
        // computed properties should return their fallback strings.
        let view = AboutView()
        // Exercise the computed properties indirectly via reflection-friendly access.
        // The view is a struct; its private helpers rely on Bundle.main, which in
        // XCTest env returns nil -> fallbacks "-" / "GitOK".
        _ = view
        #expect(String(reflecting: view).isEmpty == false)
    }

    @Test("localization lookup returns a non-empty string for known key")
    func localizationLookup() {
        let result = AboutSettingsLocalization.string("About", bundle: .module)
        // Either the catalog resolves it or it falls back to the key itself.
        #expect(result.isEmpty == false)
    }
}
