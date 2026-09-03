import Foundation
import KernelCore
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
        #expect(plugin.metadata.policy == .alwaysOn)
        #expect(plugin.dependencies.contains("com.coffic.lumi.plugin.setting-view"))
    }

    @Test("预设存储支持添加 / 删除 / 默认选择")
    func presetStore() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitUserSettingsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = GitUserConfigStore(directory: dir)
        let a = store.addPreset(name: "Alice", email: "alice@example.com")
        let b = store.addPreset(name: "Bob", email: "bob@example.com")

        #expect(store.loadPresets().count == 2)
        #expect(a.isDefault == true)
        #expect(store.findDefault()?.name == "Alice")

        store.deletePreset(id: b.id)
        #expect(store.loadPresets().count == 1)
    }
}
