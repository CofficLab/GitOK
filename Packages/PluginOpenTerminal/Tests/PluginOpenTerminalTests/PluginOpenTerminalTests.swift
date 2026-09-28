import Foundation
import KitOpenIn
import Testing
@testable import PluginOpenTerminal

@Suite("PluginOpenTerminal")
@MainActor
struct PluginOpenTerminalTests {

    @Test("plugin identity derives from terminal target")
    func identity() {
        let plugin = OpenTerminalPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.open-terminal")
        #expect(plugin.target == .terminal)
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
        #expect(plugin.order == OpenTarget.terminal.toolbarOrder)
    }

    @Test("terminal target display values")
    func targetValues() {
        #expect(OpenTarget.terminal.displayName == "Terminal")
        #expect(OpenTarget.terminal.systemImage == "terminal")
        #expect(OpenTarget.terminal.toolbarOrder == 20)
    }
}
