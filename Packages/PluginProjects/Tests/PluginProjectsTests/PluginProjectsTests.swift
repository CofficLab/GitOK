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

    func testOpenProjectAddsAndSortsByRecency() throws {
        let manager = ProjectManager(storeURL: storeURL)
        let a = URL(fileURLWithPath: "/tmp/RepoA")
        let b = URL(fileURLWithPath: "/tmp/RepoB")

        manager.openProject(at: a)
        manager.openProject(at: b)
        XCTAssertEqual(manager.projects.map(\.title), ["RepoB", "RepoA"])
        XCTAssertEqual(manager.currentProject?.title, "RepoB")

        manager.openProject(at: a)
        XCTAssertEqual(manager.projects.map(\.title), ["RepoA", "RepoB"], "最近打开应排最前")
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

        manager.pinProject(id: manager.projects[1].id, isPinned: true)
        XCTAssertEqual(manager.projects.map(\.title), ["B", "A"])
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
        XCTAssertNil(reloaded.currentProject, "当前项目不持久化")
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
