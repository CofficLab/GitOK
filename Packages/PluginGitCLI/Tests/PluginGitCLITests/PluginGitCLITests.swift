import Testing
@testable import PluginGitCLI

@Suite("PluginGitCLI")
struct PluginGitCLITests {
    @Test("CLI 插件作为内置必需后端提供稳定的插件标识")
    @MainActor
    func metadata() {
        let plugin = GitCLIPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-cli")
        #expect(plugin.metadata.policy == .required)
    }
}
