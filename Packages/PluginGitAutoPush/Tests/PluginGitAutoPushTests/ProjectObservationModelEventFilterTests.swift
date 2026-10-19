import Foundation
import KitGit
import ProviderProjects
import Testing

@testable import PluginGitAutoPush

// MARK: - Test Doubles

/// 可手动派发项目事件的 `ProjectProviding` 替身。
@MainActor
final class AutoPushTestProjectsProvider: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?

    private var callbacks: [(ProjectProvidingEvent) -> Void] = []

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
    func selectCommit(_ commit: GitCommit) {}
    func selectFile(_ path: String?) {}
    func clearCommitSelection() {}

    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        callbacks.append(callback)
        return NoopAutoPushHandle()
    }

    func emit(_ event: ProjectProvidingEvent) {
        callbacks.forEach { $0(event) }
    }
}

@MainActor
final class NoopAutoPushHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}

// MARK: - Tests

@Suite("ProjectObservationModel 事件过滤")
@MainActor
struct ProjectObservationModelEventFilterTests {

    @Test("仓库级事件记录 lastEvent 并递增 revision")
    func repositoryScopedEvents() {
        let provider = AutoPushTestProjectsProvider()
        let model = ProjectObservationModel(projects: provider)

        provider.emit(.selectionChanged(projectID: nil))
        #expect(model.revision == 1)
        if case .selectionChanged = model.lastEvent {} else {
            Issue.record("lastEvent 应为 selectionChanged")
        }

        provider.emit(.dataChanged)
        #expect(model.revision == 2)
        if case .dataChanged = model.lastEvent {} else {
            Issue.record("lastEvent 应为 dataChanged")
        }
    }

    @Test("会话级选择事件被忽略，避免无谓的状态栏刷新")
    func sessionScopedEventsIgnored() {
        let provider = AutoPushTestProjectsProvider()
        let model = ProjectObservationModel(projects: provider)

        provider.emit(.commitSelectionChanged)
        provider.emit(.currentFileChanged)

        #expect(model.revision == 0)
        #expect(model.lastEvent == nil)
    }

    @Test("项目列表变化被忽略：不影响当前项目的推送状态")
    func projectListChangeIgnored() {
        let provider = AutoPushTestProjectsProvider()
        let model = ProjectObservationModel(projects: provider)

        provider.emit(.projectsChanged)

        #expect(model.revision == 0)
        #expect(model.lastEvent == nil)
    }
}
