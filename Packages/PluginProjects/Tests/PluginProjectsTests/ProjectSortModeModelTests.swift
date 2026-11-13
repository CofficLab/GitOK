import Foundation
import ProviderProjects
import XCTest
@testable import PluginProjects

/// 项目侧边栏排序方式状态的测试。
///
/// 回归背景：排序方式曾由 `ProjectSidebarView` 以视图本地 `@State` 持有。根布局
/// 在工作区状态变化（切换项目、卷不可用等）时会重建侧边栏视图，`@State` 随之
/// 丢失，用户选中的排序方式会跳回默认值。状态改由 Provider 持有后，视图重建
/// 不应再影响排序方式。
@MainActor
final class ProjectSortModeModelTests: XCTestCase {
    func testLoadsPersistedMode() {
        let model = ProjectSortModeModel(store: InMemoryProjectSortModeStore(mode: .name))

        XCTAssertEqual(model.mode, .name)
    }

    func testFallsBackToManualWhenNothingStored() {
        let model = ProjectSortModeModel(store: InMemoryProjectSortModeStore())

        XCTAssertEqual(model.mode, .manual)
    }

    func testSetModePersistsToStore() {
        let store = InMemoryProjectSortModeStore()
        let model = ProjectSortModeModel(store: store)

        model.setMode(.recent)

        XCTAssertEqual(model.mode, .recent)
        XCTAssertEqual(store.loadSortMode(), .recent)
    }

    func testSetSameModeDoesNotWriteAgain() {
        let store = CountingSortModeStore(mode: .name)
        let model = ProjectSortModeModel(store: store)

        model.setMode(.name)

        XCTAssertEqual(store.saveCount, 0, "值未变化时不应重复写盘")
    }

    /// 侧边栏视图被根布局重建后，仍使用用户上次选择的排序方式。
    func testProviderKeepsSortModeAcrossSidebarViewRebuilds() {
        let store = InMemoryProjectSortModeStore(mode: .manual)
        let provider = ProjectSidebarProviding(
            projects: StubSidebarCapability(),
            sortModeStore: store
        )
        provider.sortModeModel.setMode(.name)

        // 根布局每次重建都会重新调用工厂方法生成侧边栏视图。
        _ = provider.makeSidebarView()
        _ = provider.makeSidebarView()

        XCTAssertEqual(provider.sortModeModel.mode, .name)
        XCTAssertEqual(store.loadSortMode(), .name)
    }
}

// MARK: - Test Doubles

@MainActor
private final class CountingSortModeStore: ProjectSortModeStoring {
    private var mode: ProjectSortMode?
    private(set) var saveCount = 0

    init(mode: ProjectSortMode?) {
        self.mode = mode
    }

    func loadSortMode() -> ProjectSortMode? { mode }

    func saveSortMode(_ mode: ProjectSortMode) {
        self.mode = mode
        saveCount += 1
    }
}

@MainActor
private final class StubSidebarCapability: ProjectSidebarCapability {
    var projects: [Project] { [] }
    var currentProject: Project? { nil }

    func addProject(at url: URL) {}
    func openProject(at url: URL) {}
    func setCurrentProject(id: UUID?) {}
    func removeProject(id: UUID) {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func moveProject(id: UUID, beforeID: UUID?) {}
    func renameProject(id: UUID, newName: String) throws {}
    func notifyDataChanged() {}

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        StubObserverHandle()
    }
}

private final class StubObserverHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}
