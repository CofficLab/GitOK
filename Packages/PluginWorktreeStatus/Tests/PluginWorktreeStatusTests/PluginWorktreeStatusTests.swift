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

    @Test("主操作根据 upstream 状态映射")
    func primaryActionMode() {
        #expect(WorktreeStatusActionMode.resolve(hasUpstream: false) == .publish)
        #expect(WorktreeStatusActionMode.resolve(hasUpstream: true) == .synchronize)
    }

    @Test("同步 badge 正确展示 ahead 和 behind")
    func syncBadgeText() {
        #expect(WorktreeSyncBadgeFormatter.text(ahead: 2, behind: 3, hasUpstream: true) == "↑2 ↓3")
        #expect(WorktreeSyncBadgeFormatter.text(ahead: 2, behind: 0, hasUpstream: true) == "↑2")
        #expect(WorktreeSyncBadgeFormatter.text(ahead: 0, behind: 4, hasUpstream: true) == "↓4")
        #expect(WorktreeSyncBadgeFormatter.text(ahead: 0, behind: 0, hasUpstream: true) == nil)
        #expect(WorktreeSyncBadgeFormatter.text(ahead: 4, behind: 1, hasUpstream: false) == nil)
    }

}
