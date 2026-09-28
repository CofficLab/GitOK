import Foundation
import Testing
@testable import PluginOpenVSCode

@Suite("PluginOpenVSCode")
@MainActor
struct PluginOpenVSCodeTests {
    @Test("插件身份与策略")
    func identity() {
        let plugin = OpenVSCodePlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.open-vscode")
        #expect(plugin.pluginPolicy == .alwaysOn)
    }
}
