import Foundation
import KernelCore
import Testing
@testable import PluginGitRepositorySettings

@Suite("PluginGitRepositorySettings")
@MainActor
struct PluginGitRepositorySettingsTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitRepositorySettingsPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-repository-settings")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
