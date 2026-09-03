import Foundation
import KernelCore
import Testing
@testable import PluginGitLFS

@Suite("PluginGitLFS")
@MainActor
struct PluginGitLFSTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitLFSPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-lfs")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
