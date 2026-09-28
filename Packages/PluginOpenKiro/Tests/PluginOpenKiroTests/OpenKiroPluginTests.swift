import Testing
@testable import PluginOpenKiro

@Suite("OpenKiroPlugin")
@MainActor
struct OpenKiroPluginTests {
    @Test("plugin instantiates with disabledByDefault policy")
    func instantiates() {
        let plugin = OpenKiroPlugin()
        #expect(plugin.pluginPolicy == .disabledByDefault)
    }
}
