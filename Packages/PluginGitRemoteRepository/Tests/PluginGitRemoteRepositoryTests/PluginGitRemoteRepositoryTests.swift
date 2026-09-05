import Foundation
import KernelCore
import Testing
@testable import PluginGitRemoteRepository

@Suite("PluginGitRemoteRepository")
@MainActor
struct PluginGitRemoteRepositoryTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitRemoteRepositoryPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-remote-repository")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
