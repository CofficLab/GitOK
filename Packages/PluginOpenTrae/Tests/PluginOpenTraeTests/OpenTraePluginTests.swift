import Testing
@testable import PluginOpenTrae

@Suite("OpenTraePlugin")
@MainActor
struct OpenTraePluginTests {
    @Test("plugin instantiates with disabledByDefault policy")
    func instantiates() {
        let plugin = OpenTraePlugin()
        #expect(plugin.pluginPolicy == .disabledByDefault)
    }
}
