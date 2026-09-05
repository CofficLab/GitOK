import Foundation
import KernelCore
import Testing
@testable import PluginGitConflictResolver

@Suite("PluginGitConflictResolver")
@MainActor
struct PluginGitConflictResolverTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitConflictResolverPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-conflict-resolver")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
