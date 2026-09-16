import Testing
@testable import PluginSettingView
import ProviderSettingView
import SwiftUI
import Foundation

@MainActor
@Suite("SettingViewManager Tests")
struct SettingViewManagerTests {

    private func makeEntry(id: String, order: Int = 200) -> SettingEntryItem {
        SettingEntryItem(id: id, title: id, systemImage: "gear", order: order) {}
    }

    /// 创建临时目录用于测试持久化。
    private func makeTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SettingViewManagerTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    /// 清理临时目录。
    private func cleanupTempDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("registerEntries 按 order 升序排列")
    func registerAndSort() {
        let manager = SettingViewManager()

        manager.registerEntries([
            makeEntry(id: "c", order: 300),
            makeEntry(id: "a", order: 100),
            makeEntry(id: "b", order: 200),
        ])

        #expect(manager.entries.map(\.id) == ["a", "b", "c"])
    }

    @Test("registerEntries 自动选中第一项")
    func autoSelectFirst() {
        let manager = SettingViewManager()

        manager.registerEntries([makeEntry(id: "first", order: 100)])

        #expect(manager.selectedEntryID == "first")
    }

    @Test("项目详情区块追加、排序并按 id 移除")
    func projectDetailSections() {
        let manager = SettingViewManager()
        let first = ProjectDetailSectionItem(id: "first", order: 200) { _ in Text("First") }
        let second = ProjectDetailSectionItem(id: "second", order: 100) { _ in Text("Second") }

        manager.addProjectDetailSections([first, second, first])

        #expect(manager.projectDetailSections.map(\.id) == ["second", "first"])

        manager.removeProjectDetailSections(ids: ["second"])

        #expect(manager.projectDetailSections.map(\.id) == ["first"])
    }

    @Test("选中入口切换")
    func selectEntry() {
        let manager = SettingViewManager()

        manager.registerEntries([
            makeEntry(id: "a", order: 100),
            makeEntry(id: "b", order: 200),
        ])
        #expect(manager.selectedEntryID == "a")

        manager.selectEntry(id: "b")
        #expect(manager.selectedEntryID == "b")
    }

    // MARK: - Persistence Tests

    @Test("无 storageDirectory 时不做持久化")
    func noPersistenceWithoutStorageDirectory() {
        let manager = SettingViewManager()

        manager.registerEntries([
            makeEntry(id: "a", order: 100),
            makeEntry(id: "b", order: 200),
        ])
        manager.selectEntry(id: "b")

        // 无 storageDirectory 时 selectedEntryID 仍正常工作，只是不写入磁盘
        #expect(manager.selectedEntryID == "b")
    }

    @Test("selectEntry 后写入磁盘，新实例可恢复")
    func persistAndRestore() {
        let tempDir = makeTempDirectory()
        defer { cleanupTempDirectory(tempDir) }

        // 第一个实例：选中 "b" 并持久化
        let manager1 = SettingViewManager(storageDirectory: tempDir)
        manager1.registerEntries([
            makeEntry(id: "a", order: 100),
            makeEntry(id: "b", order: 200),
        ])
        manager1.selectEntry(id: "b")
        #expect(manager1.selectedEntryID == "b")

        // 第二个实例：从磁盘恢复
        let manager2 = SettingViewManager(storageDirectory: tempDir)
        #expect(manager2.selectedEntryID == "b")
    }

    @Test("首次启动时文件不存在，selectedEntryID 为 nil")
    func restoreFromNonexistentFile() {
        let tempDir = makeTempDirectory()
        defer { cleanupTempDirectory(tempDir) }

        let manager = SettingViewManager(storageDirectory: tempDir)
        #expect(manager.selectedEntryID == nil)
    }

    @Test("注册 entries 后若恢复的 ID 不存在，自动选中第一项")
    func restoreInvalidIDFallsBackToFirst() {
        let tempDir = makeTempDirectory()
        defer { cleanupTempDirectory(tempDir) }

        // 先写入一个已不存在的 entry id
        let manager1 = SettingViewManager(storageDirectory: tempDir)
        manager1.registerEntries([
            makeEntry(id: "old-entry", order: 100),
        ])
        manager1.selectEntry(id: "old-entry")

        // 新实例注册不同的 entries，恢复的 id 不在列表中
        let manager2 = SettingViewManager(storageDirectory: tempDir)
        manager2.registerEntries([
            makeEntry(id: "new-a", order: 100),
            makeEntry(id: "new-b", order: 200),
        ])

        // 应自动选中第一项
        #expect(manager2.selectedEntryID == "new-a")
    }
}
