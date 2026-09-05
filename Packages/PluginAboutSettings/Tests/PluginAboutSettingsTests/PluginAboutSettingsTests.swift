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
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
