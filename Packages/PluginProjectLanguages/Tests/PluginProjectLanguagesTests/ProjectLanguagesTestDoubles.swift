import Foundation
import KitGit
import ProviderGitRepositoryWatch
import ProviderProjects

/// `ProjectProviding` 的可控替身：记录订阅并允许手动派发事件。
@MainActor
final class LanguagesProjectsStub: ProjectProviding {
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
        return LanguagesProjectHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
            self?.observerCount -= 1
        }
    }

    func send(_ event: ProjectProvidingEvent) {
        for callback in observers.values {
            callback(event)
        }
    }

    func openProject(at url: URL) { currentProject = Project(url: url) }
    func closeCurrentProject() { currentProject = nil }
    func addProject(at url: URL) { projects.append(Project(url: url)) }
    func removeProject(id: UUID) { projects.removeAll { $0.id == id } }
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func moveProject(id: UUID, beforeID: UUID?) {}
    func selectCommit(_ commit: GitCommit) { currentCommit = commit }
    func selectFile(_ file: String?) { currentFile = file }
    func clearCommitSelection() {
        currentCommit = nil
        currentFile = nil
    }
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
}

@MainActor
final class LanguagesProjectHandle: ProjectProvidingObserverHandle {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() { onCancel() }
}

/// `GitRepositoryWatching` 的可控替身：记录订阅并允许手动派发事件。
@MainActor
final class LanguagesRepositoryWatchStub: GitRepositoryWatching {
    private(set) var watchingRepositoryURL: URL?
    private var observers: [UUID: (GitRepositoryWatchingEvent) -> Void] = [:]
    private(set) var observerCount = 0

    func addObserver(
        _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
    ) -> any GitRepositoryWatchingObserverHandle {
        let id = UUID()
        observers[id] = callback
        observerCount += 1
        return LanguagesRepositoryHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
            self?.observerCount -= 1
        }
    }

    func startWatching(repositoryURL: URL) {
        watchingRepositoryURL = repositoryURL
    }

    func stopWatching() {
        watchingRepositoryURL = nil
    }

    func send(_ event: GitRepositoryWatchingEvent) {
        for callback in observers.values {
            callback(event)
        }
    }
}

@MainActor
final class LanguagesRepositoryHandle: GitRepositoryWatchingObserverHandle {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() { onCancel() }
}
