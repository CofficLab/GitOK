import Foundation
import KernelCore
import Testing
@testable import PluginGitStash

@Suite("PluginGitStash")
@MainActor
struct PluginGitStashTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitStashPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-stash")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
