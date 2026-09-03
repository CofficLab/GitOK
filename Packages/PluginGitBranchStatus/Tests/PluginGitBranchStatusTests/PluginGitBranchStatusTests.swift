import Foundation
import KernelCore
import Testing
@testable import PluginGitBranchStatus

@Suite("PluginGitBranchStatus")
@MainActor
struct PluginGitBranchStatusTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitBranchStatusPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-branch-status")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
