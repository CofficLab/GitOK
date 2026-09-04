import Foundation
import KernelCore
import ProviderGit
import Testing
@testable import PluginGitUserSettings

@Suite("PluginGitUserSettings")
@MainActor
struct PluginGitUserSettingsTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitUserSettingsPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-user-settings")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .disabled)
        #expect(plugin.dependencies.contains("com.coffic.lumi.plugin.setting-view"))
    }

    @Test("预设存储支持添加 / 删除 / 默认选择")
    func presetStore() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitUserSettingsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let provider = DefaultGitUserPresetProvider(directory: dir)
        let a = provider.addPreset(name: "Alice", email: "alice@example.com")
        let b = provider.addPreset(name: "Bob", email: "bob@example.com")

        #expect(provider.loadPresets().count == 2)
        #expect(a.isDefault == true)
        #expect(provider.findDefault()?.name == "Alice")

        provider.deletePreset(id: b.id)
        #expect(provider.loadPresets().count == 1)
    }
}
