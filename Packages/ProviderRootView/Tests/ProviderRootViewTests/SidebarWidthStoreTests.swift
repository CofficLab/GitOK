import Foundation
import Testing
@testable import GitOKProviderRootView

/// sidebar 宽度偏好的磁盘持久化测试。
@Suite("ProviderRootView SidebarWidth 存储")
@MainActor
struct SidebarWidthStoreTests {

    @Test("未存储时读不到宽度")
    func loadReturnsNilWhenNothingStored() {
        let store = makeStore()

        #expect(store.loadWidth() == nil)
    }

    @Test("保存后可读回宽度")
    func saveThenLoadRoundTrips() {
        let store = makeStore()

        store.saveWidth(360)

        #expect(store.loadWidth() == 360)
    }

    @Test("宽度落盘到插件数据目录下的 settings.plist")
    func savesToSettingsPlist() {
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PluginDataSidebarWidthStore(directory: directory, legacyDefaults: makeDefaults())

        store.saveWidth(300)

        let fileURL = directory.appendingPathComponent("settings.plist")
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        #expect(readNumber(forKey: PluginDataSidebarWidthStore.widthKey, in: directory) == 300)
    }

    @Test("重建实例后仍能读到磁盘上的宽度")
    func valueSurvivesNewStoreInstance() {
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = PluginDataSidebarWidthStore(directory: directory, legacyDefaults: makeDefaults())
        first.saveWidth(280)

        let second = PluginDataSidebarWidthStore(directory: directory, legacyDefaults: makeDefaults())

        #expect(second.loadWidth() == 280)
    }

    @Test("非法宽度不会被写入")
    func invalidWidthIsIgnored() {
        let store = makeStore()

        store.saveWidth(0)
        store.saveWidth(-10)
        store.saveWidth(.nan)
        store.saveWidth(.infinity)

        #expect(store.loadWidth() == nil)
    }

    // MARK: - Legacy Import

    @Test("旧 UserDefaults 值被一次性导入")
    func importsLegacyUserDefaultsValue() {
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let defaults = makeDefaults()
        defaults.set(320.0, forKey: PluginDataSidebarWidthStore.legacyDefaultsKey)

        let store = PluginDataSidebarWidthStore(directory: directory, legacyDefaults: defaults)

        #expect(store.loadWidth() == 320)
    }

    @Test("导入后移除旧 UserDefaults key")
    func legacyImportRemovesOldDefaultsKey() {
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let defaults = makeDefaults()
        defaults.set(320.0, forKey: PluginDataSidebarWidthStore.legacyDefaultsKey)

        _ = PluginDataSidebarWidthStore(directory: directory, legacyDefaults: defaults)

        #expect(defaults.object(forKey: PluginDataSidebarWidthStore.legacyDefaultsKey) == nil)
    }

    @Test("磁盘已有记录时不被旧值覆盖")
    func legacyImportDoesNotOverwriteExistingDiskValue() {
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PluginDataSidebarWidthStore(directory: directory, legacyDefaults: makeDefaults())
        store.saveWidth(240)
        let defaults = makeDefaults()
        defaults.set(320.0, forKey: PluginDataSidebarWidthStore.legacyDefaultsKey)

        let reopened = PluginDataSidebarWidthStore(directory: directory, legacyDefaults: defaults)

        #expect(reopened.loadWidth() == 240)
    }

    @Test("非法的旧值被丢弃")
    func legacyImportDiscardsInvalidValue() {
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let defaults = makeDefaults()
        defaults.set(0.0, forKey: PluginDataSidebarWidthStore.legacyDefaultsKey)

        let store = PluginDataSidebarWidthStore(directory: directory, legacyDefaults: defaults)

        #expect(store.loadWidth() == nil)
    }

    // MARK: - In-Memory Store

    @Test("内存存储读写行为与磁盘实现一致")
    func inMemoryStoreRoundTrips() {
        let store = InMemorySidebarWidthStore()

        #expect(store.loadWidth() == nil)

        store.saveWidth(300)

        #expect(store.loadWidth() == 300)
    }

    @Test("宿主注入目录后 Provider 恢复已保存的宽度")
    func providerRestoresWidthFromInjectedDirectory() {
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PluginDataSidebarWidthStore(directory: directory, legacyDefaults: makeDefaults())
        store.saveWidth(310)

        let provider = DefaultRootViewProvider()
        provider.setStorageDirectory(directory)

        #expect(provider.sidebarWidth.idealWidth == 310)
    }

    // MARK: - Helpers

    private func makeDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("SidebarWidthStoreTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "SidebarWidthStoreTests-\(UUID().uuidString)")!
    }

    private func makeStore() -> PluginDataSidebarWidthStore {
        PluginDataSidebarWidthStore(directory: makeDirectory(), legacyDefaults: makeDefaults())
    }

    private func readNumber(forKey key: String, in directory: URL) -> Double? {
        let fileURL = directory.appendingPathComponent("settings.plist")
        guard let data = try? Data(contentsOf: fileURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any] else {
            return nil
        }
        return (dict[key] as? NSNumber)?.doubleValue
    }
}
