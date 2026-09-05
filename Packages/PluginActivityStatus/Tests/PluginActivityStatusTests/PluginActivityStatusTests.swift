import Foundation
import KernelCore
import Testing
@testable import PluginActivityStatus

@Suite("PluginActivityStatus")
@MainActor
struct PluginActivityStatusTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = ActivityStatusPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.activity-status")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
