import Foundation
import KernelCore
import Testing
@testable import PluginCloneRepository

@Suite("PluginCloneRepository")
@MainActor
struct PluginCloneRepositoryTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = CloneRepositoryPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.clone-repository")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
