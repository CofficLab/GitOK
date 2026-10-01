import Testing
@testable import PluginOpenRemote

@Suite("PluginOpenRemote")
@MainActor
struct OpenRemotePluginTests {
    @Test("policy is alwaysOn and id derives from remote target")
    func pluginIdentity() {
        let plugin = OpenRemotePlugin()
        #expect(plugin.pluginPolicy == .alwaysOn)
        #expect(plugin.id == "com.coffic.gitok.plugin.open-remote")
        #expect(plugin.metadata.policy == .alwaysOn)
        #expect(plugin.target == .remote)
        #expect(plugin.target.isAlwaysAvailable)
    }
}
