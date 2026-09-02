import Foundation
import ProviderProjects
import XCTest
@testable import PluginProjects

@MainActor
final class PluginProjectsTests: XCTestCase {
    private var tempDir: URL!
    private var storeURL: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginProjectsTests-\(UUID().uuidString)", isDirectory: true)
        storeURL = tempDir.appendingPathComponent("projects.json")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testOpenProjectAddsNewProjectsToFrontWithoutReorderingOnOpen() throws {
        let manager = ProjectManager(storeURL: storeURL)
        let a = URL(fileURLWithPath: "/tmp/RepoA")
        let b = URL(fileURLWithPath: "/tmp/RepoB")

        manager.openProject(at: a)
        manager.openProject(at: b)
        XCTAssertEqual(manager.projects.map(\.title), ["RepoB", "RepoA"], "新项目插入最前")
        XCTAssertEqual(manager.currentProject?.title, "RepoB")

        // 再次打开已存在的项目：只切换当前项目，不重排（对齐旧版）。
        manager.openProject(at: a)
        XCTAssertEqual(manager.projects.map(\.title), ["RepoB", "RepoA"], "打开已有项目不应改变列表顺序")
        XCTAssertEqual(manager.currentProject?.title, "RepoA")
    }

    func testAddProjectDeduplicates() {
        let manager = ProjectManager(storeURL: storeURL)
        let url = URL(fileURLWithPath: "/tmp/RepoA")
        manager.addProject(at: url)
        manager.addProject(at: url)
        XCTAssertEqual(manager.projects.count, 1)
    }

    func testRemoveProjectClearsCurrent() {
        let manager = ProjectManager(storeURL: storeURL)
        let url = URL(fileURLWithPath: "/tmp/RepoA")
        manager.openProject(at: url)
        XCTAssertNotNil(manager.currentProject)

        manager.removeProject(id: manager.projects[0].id)
        XCTAssertTrue(manager.projects.isEmpty)
        XCTAssertNil(manager.currentProject)
    }

    func testPinSortsToTop() {
        let manager = ProjectManager(storeURL: storeURL)
        manager.addProject(at: URL(fileURLWithPath: "/tmp/A"))
        manager.addProject(at: URL(fileURLWithPath: "/tmp/B"))

        // 新项目在前：["B", "A"]；置顶 A 应使其排到最前。
        manager.pinProject(id: manager.projects[1].id, isPinned: true)
        XCTAssertEqual(manager.projects.map(\.title), ["A", "B"])
    }

    func testPersistenceRoundTrip() throws {
        let manager = ProjectManager(storeURL: storeURL)
        manager.addProject(at: URL(fileURLWithPath: "/tmp/A"))
        manager.openProject(at: URL(fileURLWithPath: "/tmp/B"))
        manager.pinProject(id: manager.projects.first(where: { $0.title == "A" })!.id, isPinned: true)

        // 重新加载
        let reloaded = ProjectManager(storeURL: storeURL)
        XCTAssertEqual(reloaded.projects.count, 2)
        XCTAssertEqual(reloaded.projects.map(\.title), ["A", "B"], "置顶 A 应排最前")
        XCTAssertEqual(reloaded.currentProject?.title, "B", "当前项目应持久化并在重启后恢复")
    }

    func testCurrentProjectPersistsAcrossReload() throws {
        let manager = ProjectManager(storeURL: storeURL)
        let a = URL(fileURLWithPath: "/tmp/RepoA")
        let b = URL(fileURLWithPath: "/tmp/RepoB")
        manager.addProject(at: a)
        manager.addProject(at: b)
        manager.setCurrentProject(id: manager.projects.first(where: { $0.title == "RepoA" })!.id)

        // 重新加载后应恢复上次的当前项目。
        let reloaded = ProjectManager(storeURL: storeURL)
        XCTAssertEqual(reloaded.currentProject?.title, "RepoA")
    }

    func testCloseCurrentProjectPersistsClear() throws {
        let manager = ProjectManager(storeURL: storeURL)
        manager.openProject(at: URL(fileURLWithPath: "/tmp/RepoA"))
        manager.closeCurrentProject()

        // 关闭当前项目后，重启不应恢复任何当前项目。
        let reloaded = ProjectManager(storeURL: storeURL)
        XCTAssertNil(reloaded.currentProject)
    }

    func testLegacyArrayFormatStillLoads() throws {
        // 旧版存储是纯 [Project] 数组；应能兼容读取且不崩。
        let manager = ProjectManager(storeURL: storeURL)
        manager.addProject(at: URL(fileURLWithPath: "/tmp/A"))
        manager.addProject(at: URL(fileURLWithPath: "/tmp/B"))
        let legacyData = try JSONEncoder().encode(manager.projects)
        try legacyData.write(to: storeURL)

        let reloaded = ProjectManager(storeURL: storeURL)
        XCTAssertEqual(reloaded.projects.count, 2)
        XCTAssertNil(reloaded.currentProject)
    }

    func testSetStoreURLReloads() throws {
        let manager = ProjectManager(storeURL: storeURL)
        manager.addProject(at: URL(fileURLWithPath: "/tmp/A"))

        let otherURL = tempDir.appendingPathComponent("other.json")
        manager.setStoreURL(otherURL)
        XCTAssertTrue(manager.projects.isEmpty, "切换到新目录后应重新加载（为空）")

        manager.addProject(at: URL(fileURLWithPath: "/tmp/B"))
        let reloaded = ProjectManager(storeURL: otherURL)
        XCTAssertEqual(reloaded.projects.map(\.title), ["B"])
    }

    // MARK: - Observation

    func testAddProjectNotifiesProjectsChanged() {
        let manager = ProjectManager(storeURL: storeURL)
        var events: [ProjectProvidingEvent] = []
        let handle = manager.addObserver { events.append($0) }

        manager.addProject(at: URL(fileURLWithPath: "/tmp/A"))

        XCTAssertTrue(events.contains { if case .projectsChanged = $0 { return true }; return false },
                      "添加项目应通知 projectsChanged，驱动 UI 刷新")
        handle.cancel()
    }

    func testOpenProjectNotifiesSelectionAndProjectsChanged() {
        let manager = ProjectManager(storeURL: storeURL)
        manager.addProject(at: URL(fileURLWithPath: "/tmp/A"))

        var events: [ProjectProvidingEvent] = []
        let handle = manager.addObserver { events.append($0) }

        manager.openProject(at: URL(fileURLWithPath: "/tmp/A"))

        XCTAssertTrue(events.contains { if case .projectsChanged = $0 { return true }; return false })
        XCTAssertTrue(events.contains {
            if case .selectionChanged = $0 { return true }; return false
        }, "打开项目应通知 selectionChanged")
        handle.cancel()
    }

    func testCloseCurrentProjectNotifiesSelectionChanged() {
        let manager = ProjectManager(storeURL: storeURL)
        manager.openProject(at: URL(fileURLWithPath: "/tmp/A"))

        var events: [ProjectProvidingEvent] = []
        let handle = manager.addObserver { events.append($0) }

        manager.closeCurrentProject()

        XCTAssertTrue(events.contains {
            if case .selectionChanged(projectID: nil) = $0 { return true }; return false
        })
        handle.cancel()
    }

    func testCancelStopsNotifications() {
        let manager = ProjectManager(storeURL: storeURL)
        var count = 0
        let handle = manager.addObserver { _ in count += 1 }

        handle.cancel()
        manager.addProject(at: URL(fileURLWithPath: "/tmp/A"))
        manager.openProject(at: URL(fileURLWithPath: "/tmp/A"))

        XCTAssertEqual(count, 0, "cancel 后不应再收到事件")
    }
}
