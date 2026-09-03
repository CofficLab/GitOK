import Foundation
import KernelCore
import Testing
@testable import PluginProjectPicker

@Suite("PluginProjectPicker")
@MainActor
struct PluginProjectPickerTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = ProjectPickerPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.project-picker")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
