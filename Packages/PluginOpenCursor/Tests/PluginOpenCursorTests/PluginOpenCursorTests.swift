import Foundation
import Testing
@testable import PluginOpenCursor

@Suite("PluginOpenCursor")
@MainActor
struct PluginOpenCursorTests {
    @Test("插件身份与策略")
    func identity() {
        let plugin = OpenCursorPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.open-cursor")
        #expect(plugin.pluginPolicy == .disabledByDefault)
    }
}
