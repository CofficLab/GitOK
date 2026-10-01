import Foundation
import KernelCore
import Testing
@testable import PluginGitAutoPush

@Suite("PluginGitAutoPush")
@MainActor
struct PluginGitAutoPushTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitAutoPushPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-auto-push")
        #expect(plugin.metadata.id == plugin.id)
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
        #expect(plugin.metadata.stage == .stable)
        #expect(plugin.order == 39)
        #expect(GitAutoPushPlugin.itemID == "com.coffic.gitok.plugin.git-auto-push.id")
    }
}
