import Foundation
import ProviderProjects
import XCTest
@testable import PluginSidebar

@MainActor
final class PluginSidebarTests: XCTestCase {
    func testSidebarProvidingReturnsView() {
        let projects = MockProjectProviding()
        let sidebar = ProjectSidebarProviding(projects: projects)
        let view = sidebar.makeSidebarView()
        XCTAssertNotNil(view)
        XCTAssertTrue(sidebar.items.isEmpty)
    }
}

/// 测试用项目管理桩。
@MainActor
private final class MockProjectProviding: ProjectProviding, ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published private(set) var currentProject: Project?

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func persist() {}
}
