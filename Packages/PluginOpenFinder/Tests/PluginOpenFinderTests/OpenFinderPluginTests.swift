import Testing
@testable import PluginOpenFinder

@Suite("PluginOpenFinder")
@MainActor
struct OpenFinderPluginTests {
    @Test("policy is alwaysOn and id derives from finder target")
    func pluginIdentity() {
        let plugin = OpenFinderPlugin()
        #expect(plugin.pluginPolicy == .alwaysOn)
        #expect(plugin.id == "com.coffic.gitok.plugin.open-finder")
        #expect(plugin.metadata.policy == .alwaysOn)
        #expect(plugin.target.rawValue == "finder")
    }
}
