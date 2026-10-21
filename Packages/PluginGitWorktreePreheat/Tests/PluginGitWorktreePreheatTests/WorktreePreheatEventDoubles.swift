import Foundation
import KernelCore
import KitGit
import ProviderGitRepositoryWatch
import ProviderProjects

/// 可主动派发事件的 `ProjectProviding` 替身。
@MainActor
final class EventProjects: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?

    private var observers: [UUID: (ProjectProvidingEvent) -> Void] = [:]
    private(set) var observerCount = 0

    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        let id = UUID()
        observers[id] = callback
        observerCount += 1
        return EventProjectHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
            self?.observerCount -= 1
        }
    }

    /// 主动派发项目事件。
    func send(_ event: ProjectProvidingEvent) {
        for callback in observers.values { callback(event) }
    }

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func moveProject(id: UUID, beforeID: UUID?) {}
    func selectCommit(_ commit: GitCommit) {}
    func selectFile(_ file: String?) {}
    func clearCommitSelection() {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
}

@MainActor
final class EventProjectHandle: ProjectProvidingObserverHandle {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() { onCancel() }
}

/// 可主动派发事件的 `GitRepositoryWatching` 替身。
@MainActor
final class EventGitWatch: GitRepositoryWatching {
    var watchingRepositoryURL: URL?
    private var observers: [UUID: (GitRepositoryWatchingEvent) -> Void] = [:]
    private(set) var observerCount = 0

    func addObserver(
        _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
    ) -> any GitRepositoryWatchingObserverHandle {
        let id = UUID()
        observers[id] = callback
        observerCount += 1
        return EventGitWatchHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
            self?.observerCount -= 1
        }
    }

    /// 主动派发仓库监听事件。
    func send(_ event: GitRepositoryWatchingEvent) {
        for callback in observers.values { callback(event) }
    }

    func startWatching(repositoryURL: URL) {
        watchingRepositoryURL = repositoryURL
        send(.started(repositoryURL: repositoryURL))
    }

    func stopWatching() {
        watchingRepositoryURL = nil
        send(.stopped)
    }
}

@MainActor
final class EventGitWatchHandle: GitRepositoryWatchingObserverHandle {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() { onCancel() }
}
