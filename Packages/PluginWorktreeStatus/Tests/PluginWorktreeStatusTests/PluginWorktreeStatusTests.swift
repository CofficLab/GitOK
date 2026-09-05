import Foundation
import KernelCore
import Testing
@testable import PluginWorktreeStatus

@Suite("PluginWorktreeStatus")
@MainActor
struct PluginWorktreeStatusTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = WorktreeStatusPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.worktree-status")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
        #expect(plugin.dependencies.contains("com.coffic.lumi.plugin.projects"))
    }
}
