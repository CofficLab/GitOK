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
        #expect(plugin.metadata.policy == .required)
    }

    @Test("同步失败在用户确认前保持可见")
    func syncFailureRequiresDismissal() {
        let center = WorktreeSyncFailureCenter()

        center.present(operation: "拉取失败", message: "hint: divergent branches")

        #expect(center.failure?.operation == "拉取失败")
        #expect(center.failure?.message == "hint: divergent branches")

        center.dismiss()

        #expect(center.failure == nil)
    }
}
