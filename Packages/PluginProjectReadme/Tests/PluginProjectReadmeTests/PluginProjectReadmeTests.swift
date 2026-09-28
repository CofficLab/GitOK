import Foundation
import Testing
@testable import PluginProjectReadme

@Suite("PluginProjectReadme")
@MainActor
struct PluginProjectReadmeTests {
    @Test("插件元数据")
    func metadata() {
        let plugin = ProjectReadmePlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.project-readme")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .required)
        #expect(plugin.order == 21)
    }
}
