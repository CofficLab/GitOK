import Testing
@testable import PluginGitLibGit2

@Suite("PluginGitLibGit2")
struct PluginGitLibGit2Tests {
    @Test("LibGit2 插件作为内置必需后端并使用固定版本")
    @MainActor
    func metadata() {
        let plugin = GitLibGit2Plugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-libgit2")
        #expect(plugin.metadata.policy == .required)
    }
}
