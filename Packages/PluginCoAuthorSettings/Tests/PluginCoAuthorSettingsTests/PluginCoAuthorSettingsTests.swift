import Foundation
import Testing
@testable import PluginCoAuthorSettings

@Suite("PluginCoAuthorSettings")
@MainActor
struct PluginCoAuthorSettingsTests {
    @Test("Plugin has correct metadata")
    func testPluginMetadata() {
        let plugin = CoAuthorSettingsPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.coauthor-settings")
        #expect(plugin.order == 20)
        #expect(plugin.metadata.name == "Co-Author Settings")
    }
}
