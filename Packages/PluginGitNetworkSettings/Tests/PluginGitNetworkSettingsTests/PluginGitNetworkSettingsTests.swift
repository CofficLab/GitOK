import Foundation
import KernelCore
import Testing
@testable import PluginGitNetworkSettings

@Suite("PluginGitNetworkSettings")
@MainActor
struct PluginGitNetworkSettingsTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitNetworkSettingsPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-network-settings")
        #expect(plugin.metadata.category == .project)
        // 源文件声明 policy 为 .disabled（由宿主按需启用设置项）。
        #expect(plugin.metadata.policy == .disabled)
    }
}
