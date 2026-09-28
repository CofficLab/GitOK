import Testing
@testable import PluginOpenAntigravity

@Suite("OpenAntigravityPlugin")
@MainActor
struct OpenAntigravityPluginTests {
    @Test("plugin instantiates with disabledByDefault policy")
    func instantiates() {
        let plugin = OpenAntigravityPlugin()
        #expect(plugin.pluginPolicy == .disabledByDefault)
    }
}
