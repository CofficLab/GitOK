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
private final class MockProjectProviding: ProjectProviding {
    private(set) var projects: [Project] = []
    private(set) var currentProject: Project?

    func addObserver(_ callback: @escaping (ProjectProvidingEvent) -> Void) -> any ProjectProvidingObserverHandle {
        NoopObserver(callback: callback)
    }

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func persist() {}

    private final class NoopObserver: ProjectProvidingObserverHandle {
        private let callback: (ProjectProvidingEvent) -> Void

        init(callback: @escaping (ProjectProvidingEvent) -> Void) {
            self.callback = callback
        }

        func cancel() {}
    }
}
