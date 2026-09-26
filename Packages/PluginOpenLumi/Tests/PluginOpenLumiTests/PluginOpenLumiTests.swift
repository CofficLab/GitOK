import Foundation
import Testing
@testable import PluginOpenLumi

@Suite("PluginOpenLumi")
@MainActor
struct PluginOpenLumiTests {
    @Test("插件身份与策略")
    func identity() {
        let plugin = OpenLumiPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.open-lumi")
        #expect(plugin.pluginPolicy == .alwaysOn)
    }
}
