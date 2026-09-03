import Foundation
import KernelCore
import Testing
@testable import PluginCommitForm

@Suite("PluginCommitForm")
@MainActor
struct PluginCommitFormTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = CommitFormPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.commit-form")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
        #expect(plugin.dependencies.contains("com.coffic.lumi.plugin.projects"))
    }
}
