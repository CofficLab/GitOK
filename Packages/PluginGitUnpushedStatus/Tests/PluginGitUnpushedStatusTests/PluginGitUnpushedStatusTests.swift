import Foundation
import KernelCore
import Testing
@testable import PluginGitUnpushedStatus

@Suite("PluginGitUnpushedStatus")
@MainActor
struct PluginGitUnpushedStatusTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitUnpushedStatusPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-unpushed-status")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
