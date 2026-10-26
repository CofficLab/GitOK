import Foundation
import KitGit
import ProviderProjects

/// 一个最小的 `ProjectProviding` 测试替身。
///
/// 只实现本组测试需要的部分：当前项目、commit 选择状态，以及一个可以主动
/// 广播事件的观察者列表。
final class WorktreeOwnerProjectsDouble: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?

    private var observers: [(id: UUID, callback: (ProjectProvidingEvent) -> Void)] = []

    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        let id = UUID()
        observers.append((id: id, callback: callback))
        return Handle { [weak self] in
            self?.observers.removeAll { $0.id == id }
        }
    }

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func persist() {}
    func selectCommit(_ commit: GitCommit) { currentCommit = commit }
    func selectFile(_ path: String?) { currentFile = path }
    func clearCommitSelection() {
        currentCommit = nil
        currentFile = nil
        currentCommitFiles = nil
        isLoadingCommitFiles = false
        currentCommitFilesLoadError = nil
    }
    func notifyDataChanged() {
        for observer in observers { observer.callback(.dataChanged) }
    }

    /// 测试辅助：模拟「用户切换了当前项目」。
    func simulateSelectionChange(to url: URL?) {
        currentProject = url.map { Project(url: $0, lastOpenedAt: Date()) }
        for observer in observers {
            observer.callback(.selectionChanged(projectID: currentProject?.id))
        }
    }

    private final class Handle: ProjectProvidingObserverHandle {
        private let onCancel: () -> Void
        init(onCancel: @escaping () -> Void) { self.onCancel = onCancel }
        func cancel() { onCancel() }
    }
}
