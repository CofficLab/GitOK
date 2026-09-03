import Foundation
import KernelCore
import Testing
@testable import PluginGitCommitStyleSettings

@Suite("PluginGitCommitStyleSettings")
@MainActor
struct PluginGitCommitStyleSettingsTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitCommitStyleSettingsPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-commit-style-settings")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
