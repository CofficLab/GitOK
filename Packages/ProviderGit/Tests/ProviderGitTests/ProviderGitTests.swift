import Foundation
import Testing
@testable import ProviderGit

@Suite("ProviderGit")
@MainActor
struct ProviderGitTests {

    /// 生成一个独立临时目录，测试结束后自动清理。
    private func makeTemporaryDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProviderGitTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("空存储：无预设，无默认")
    func emptyStore() throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let provider = DefaultGitUserPresetProvider(directory: dir)
        #expect(provider.loadPresets().isEmpty)
        #expect(provider.findDefault() == nil)
    }

    @Test("添加多条预设，首条自动成为默认")
    func addPresetsAndFirstIsDefault() throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let provider = DefaultGitUserPresetProvider(directory: dir)
        let a = provider.addPreset(name: "Alice", email: "alice@example.com")
        let b = provider.addPreset(name: "Bob", email: "bob@example.com")
        let c = provider.addPreset(name: "Carol", email: "carol@example.com")

        #expect(provider.loadPresets().count == 3)
        #expect(a.isDefault == true)
        #expect(b.isDefault == false)
        #expect(c.isDefault == false)
        #expect(provider.findDefault()?.id == a.id)
    }

    @Test("setDefault 将指定预设设为唯一默认")
    func setDefaultIsUnique() throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let provider = DefaultGitUserPresetProvider(directory: dir)
        let a = provider.addPreset(name: "Alice", email: "alice@example.com")
        let b = provider.addPreset(name: "Bob", email: "bob@example.com")

        provider.setDefault(b)
        let presets = provider.loadPresets()
        #expect(presets.filter { $0.isDefault }.count == 1)
        #expect(provider.findDefault()?.id == b.id)
        #expect(presets.first { $0.id == a.id }?.isDefault == false)
    }

    @Test("删除默认预设后剩余第一条接任默认")
    func deleteDefaultHandsOver() throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let provider = DefaultGitUserPresetProvider(directory: dir)
        let a = provider.addPreset(name: "Alice", email: "alice@example.com")
        let b = provider.addPreset(name: "Bob", email: "bob@example.com")

        provider.deletePreset(id: a.id)
        let presets = provider.loadPresets()
        #expect(presets.count == 1)
        #expect(presets.first?.id == b.id)
        #expect(provider.findDefault()?.id == b.id)
    }

    @Test("删除非默认预设不影响默认标记")
    func deleteNonDefaultKeepsDefault() throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let provider = DefaultGitUserPresetProvider(directory: dir)
        let a = provider.addPreset(name: "Alice", email: "alice@example.com")
        let b = provider.addPreset(name: "Bob", email: "bob@example.com")

        provider.deletePreset(id: b.id)
        #expect(provider.loadPresets().count == 1)
        #expect(provider.findDefault()?.id == a.id)
    }

    @Test("clearAllDefaults 清除全部默认标记")
    func clearAllDefaults() throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let provider = DefaultGitUserPresetProvider(directory: dir)
        provider.addPreset(name: "Alice", email: "alice@example.com")

        provider.clearAllDefaults()
        let presets = provider.loadPresets()
        #expect(presets.allSatisfy { !$0.isDefault })
        // findDefault 退回第一条（不再以 isDefault 为准）。
        #expect(provider.findDefault()?.name == "Alice")
    }

    @Test("updatePreset 按 id 更新")
    func updatePreset() throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let provider = DefaultGitUserPresetProvider(directory: dir)
        let a = provider.addPreset(name: "Alice", email: "alice@example.com")

        var updated = a
        updated.email = "alice@work.example.com"
        provider.updatePreset(updated)

        let loaded = provider.loadPresets().first { $0.id == a.id }
        #expect(loaded?.email == "alice@work.example.com")
        #expect(loaded?.name == "Alice")
    }

    @Test("持久化到磁盘后可重新读取")
    func persistenceAcrossInstances() throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let first = DefaultGitUserPresetProvider(directory: dir)
        first.addPreset(name: "Alice", email: "alice@example.com")
        first.addPreset(name: "Bob", email: "bob@example.com")

        let second = DefaultGitUserPresetProvider(directory: dir)
        let presets = second.loadPresets()
        #expect(presets.count == 2)
        #expect(presets.first?.name == "Alice")
        #expect(presets.first?.isDefault == true)
    }
}
