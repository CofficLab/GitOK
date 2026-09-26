import Testing
@testable import PluginStorage
import Foundation

@Suite("PluginStorage")
@MainActor
struct PluginStorageTests {

    @Test("StorageService creates plugin and core directories")
    func storageServiceDirectories() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginStorage-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let service = StorageService(dataRootDirectory: root)
        let pluginDir = service.pluginDataDirectory(for: "com.example.plugin")
        let coreDir = service.coreDataDirectory()

        #expect(FileManager.default.fileExists(atPath: pluginDir.path))
        #expect(FileManager.default.fileExists(atPath: coreDir.path))
        #expect(pluginDir.path.hasSuffix("com.example.plugin"))
        #expect(coreDir.path.hasSuffix("Core"))
    }

    @Test("StorageSuperPlugin init with explicit root")
    func storageSuperPluginInit() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginStorage-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let plugin = try StorageSuperPlugin(dataRootDirectory: root)
        #expect(plugin.dataRootDirectory == root.standardizedFileURL)
        #expect(plugin.id == "com.coffic.gitok.plugin.storage")
    }

    @Test("StorageSuperPlugin convenience init does not crash")
    func convenienceInit() throws {
        // 默认 init 写入 Application Support；仅验证不抛错。
        let plugin = try StorageSuperPlugin()
        #expect(plugin.dataRootDirectory.path.isEmpty == false)
    }
}
