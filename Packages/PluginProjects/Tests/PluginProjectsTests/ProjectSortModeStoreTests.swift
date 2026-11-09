import Foundation
import XCTest
@testable import PluginProjects

/// 项目展示方式偏好的持久化测试。
@MainActor
final class ProjectSortModeStoreTests: XCTestCase {
    private var directory: URL!
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginProjectsSortModeTests-\(UUID().uuidString)", isDirectory: true)
        suiteName = "PluginProjectsSortModeTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        defaults.removePersistentDomain(forName: suiteName)
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func testLoadReturnsNilWhenNothingStored() {
        let store = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)

        XCTAssertNil(store.loadSortMode())
    }

    func testSaveThenLoadRoundTrips() {
        let store = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)

        store.saveSortMode(.name)

        XCTAssertEqual(store.loadSortMode(), .name)
    }

    func testLoadIgnoresUnknownStoredValue() {
        let store = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)
        store.saveSortMode(.name)
        // 手工写入一个无法识别的值，模拟存档损坏 / 版本演进。
        writeRawString("not-a-mode", forKey: PluginDataProjectSortModeStore.sortModeKey)

        XCTAssertNil(store.loadSortMode(), "无法识别的存档应回落到默认展示方式")
    }

    func testSavePersistsToSettingsPlist() {
        let store = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)

        store.saveSortMode(.recent)

        let fileURL = directory.appendingPathComponent("settings.plist")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: fileURL.path),
            "排序偏好应落盘到插件数据目录下的 settings.plist"
        )
        XCTAssertEqual(readRawString(forKey: PluginDataProjectSortModeStore.sortModeKey), "recent")
    }

    func testSavedValueSurvivesNewStoreInstance() {
        let first = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)
        first.saveSortMode(.name)

        let second = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)

        XCTAssertEqual(second.loadSortMode(), .name, "磁盘是唯一数据源，重建实例后仍能读到")
    }

    // MARK: - Legacy Import

    func testImportsLegacyUserDefaultsValue() {
        defaults.set(ProjectSortMode.recent.rawValue, forKey: PluginDataProjectSortModeStore.legacyDefaultsKey)

        let store = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)

        XCTAssertEqual(store.loadSortMode(), .recent, "旧 UserDefaults 值应被一次性导入")
    }

    func testLegacyImportRemovesOldDefaultsKey() {
        defaults.set(ProjectSortMode.recent.rawValue, forKey: PluginDataProjectSortModeStore.legacyDefaultsKey)

        _ = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)

        XCTAssertNil(
            defaults.string(forKey: PluginDataProjectSortModeStore.legacyDefaultsKey),
            "导入后应移除旧 key，避免重复导入"
        )
    }

    func testLegacyImportDoesNotOverwriteExistingDiskValue() {
        let store = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)
        store.saveSortMode(.name)
        defaults.set(ProjectSortMode.recent.rawValue, forKey: PluginDataProjectSortModeStore.legacyDefaultsKey)

        let reopened = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)

        XCTAssertEqual(reopened.loadSortMode(), .name, "磁盘已有记录时不被旧值覆盖")
    }

    func testLegacyImportDiscardsInvalidValue() {
        defaults.set("not-a-mode", forKey: PluginDataProjectSortModeStore.legacyDefaultsKey)

        let store = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)

        XCTAssertNil(store.loadSortMode(), "无法识别的旧值应被丢弃")
        XCTAssertNil(
            defaults.string(forKey: PluginDataProjectSortModeStore.legacyDefaultsKey),
            "旧 key 仍应被移除"
        )
    }

    func testNoLegacyImportWhenDefaultsEmpty() {
        let store = PluginDataProjectSortModeStore(directory: directory, legacyDefaults: defaults)

        XCTAssertNil(store.loadSortMode())
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: directory.appendingPathComponent("settings.plist").path
            ),
            "没有旧值时不应无谓地创建文件"
        )
    }

    // MARK: - In-Memory Store

    func testInMemoryStoreRoundTrips() {
        let store = InMemoryProjectSortModeStore()

        XCTAssertNil(store.loadSortMode())

        store.saveSortMode(.name)

        XCTAssertEqual(store.loadSortMode(), .name)
    }

    // MARK: - Helpers

    private func readRawString(forKey key: String) -> String? {
        let fileURL = directory.appendingPathComponent("settings.plist")
        guard let data = try? Data(contentsOf: fileURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any] else {
            return nil
        }
        return dict[key] as? String
    }

    private func writeRawString(_ value: String, forKey key: String) {
        let fileURL = directory.appendingPathComponent("settings.plist")
        var dict: [String: Any] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
           let existing = plist as? [String: Any] {
            dict = existing
        }
        dict[key] = value
        guard let data = try? PropertyListSerialization.data(
            fromPropertyList: dict,
            format: .binary,
            options: 0
        ) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
