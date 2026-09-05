import Foundation
import KernelCore
import Testing
@testable import PluginFileInfo

@Suite("PluginFileInfo")
@MainActor
struct PluginFileInfoTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = FileInfoPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.file-info")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
