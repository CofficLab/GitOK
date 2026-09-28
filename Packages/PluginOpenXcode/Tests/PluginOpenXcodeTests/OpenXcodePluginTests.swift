import Testing
@testable import PluginOpenXcode

@Suite("PluginOpenXcode")
@MainActor
struct OpenXcodePluginTests {
    @Test("policy is alwaysOn and id derives from xcode target")
    func pluginIdentity() {
        let plugin = OpenXcodePlugin()
        #expect(plugin.pluginPolicy == .alwaysOn)
        #expect(plugin.id == "com.coffic.gitok.plugin.open-xcode")
        #expect(plugin.metadata.policy == .alwaysOn)
        #expect(plugin.target == .xcode)
    }
}
