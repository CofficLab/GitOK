import Foundation
import KernelCore
import Testing
@testable import PluginGitSubmodule

@Suite("PluginGitSubmodule")
@MainActor
struct PluginGitSubmoduleTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitSubmodulePlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-submodule")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
