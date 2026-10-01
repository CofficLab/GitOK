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
        #expect(plugin.metadata.id == plugin.id)
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .disabled)
        #expect(plugin.metadata.stage == .stable)
        #expect(plugin.metadata.name == "Activity Status")
        #expect(!plugin.metadata.description.isEmpty)
        #expect(plugin.order == 31)
        #expect(ActivityStatusPlugin.itemID == "com.coffic.gitok.plugin.activity-status.id")
    }
}
