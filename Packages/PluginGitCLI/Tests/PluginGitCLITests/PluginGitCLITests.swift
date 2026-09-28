import Testing
@testable import PluginGitCLI
import ProviderGit

@Suite("PluginGitCLI")
struct PluginGitCLITests {
    @Test("CLI 插件作为内置必需后端提供稳定的插件标识")
    @MainActor
    func metadata() {
        let plugin = GitCLIPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-cli")
        #expect(plugin.metadata.policy == .required)
    }

    @Test("GitCLIBackend exposes CLI descriptor and availability")
    func backendDescriptor() {
        let backend = GitCLIBackend()
        #expect(backend.descriptor.id == "com.coffic.gitok.git-backend.cli")
        #expect(backend.descriptor.name == "Git CLI")
        // isAvailable reads whether git is on PATH; just exercise the property.
        _ = backend.isAvailable
    }
}
