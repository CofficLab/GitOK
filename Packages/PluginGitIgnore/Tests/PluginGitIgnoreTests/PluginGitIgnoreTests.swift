import Foundation
import KernelCore
import Testing
@testable import PluginGitIgnore

@Suite("PluginGitIgnore")
@MainActor
struct PluginGitIgnoreTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitIgnorePlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-ignore")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
