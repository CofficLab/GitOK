import Foundation
import KernelCore
import Testing
@testable import PluginDiagnosticsSettings

@Suite("PluginDiagnosticsSettings")
@MainActor
struct PluginDiagnosticsSettingsTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = DiagnosticsSettingsPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.diagnostics-settings")
        #expect(plugin.metadata.category == .system)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
