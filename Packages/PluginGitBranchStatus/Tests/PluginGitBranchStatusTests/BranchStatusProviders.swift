import Foundation
import KitGit
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderWorkspaceScene

// MARK: - Projects

/// `ProjectProviding` 的可控替身：记录订阅并允许手动派发事件。
@MainActor
final class BranchStatusProjectsProviding: ProjectProviding {
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
        return BranchStatusProjectHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
            self?.observerCount -= 1
        }
    }

    func send(_ event: ProjectProvidingEvent) {
        for callback in observers.values { callback(event) }
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
final class BranchStatusProjectHandle: ProjectProvidingObserverHandle {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() { onCancel() }
}

// MARK: - Repository watch

/// `GitRepositoryWatching` 的可控替身。
@MainActor
final class BranchStatusRepositoryWatching: GitRepositoryWatching {
    private(set) var watchingRepositoryURL: URL?
    private var observers: [UUID: (GitRepositoryWatchingEvent) -> Void] = [:]
    private(set) var observerCount = 0

    func addObserver(
        _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
    ) -> any GitRepositoryWatchingObserverHandle {
        let id = UUID()
        observers[id] = callback
        observerCount += 1
        return BranchStatusRepositoryHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
            self?.observerCount -= 1
        }
    }

    func startWatching(repositoryURL: URL) { watchingRepositoryURL = repositoryURL }
    func stopWatching() { watchingRepositoryURL = nil }

    func send(_ event: GitRepositoryWatchingEvent) {
        for callback in observers.values { callback(event) }
    }
}

@MainActor
final class BranchStatusRepositoryHandle: GitRepositoryWatchingObserverHandle {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() { onCancel() }
}

// MARK: - Workspace scene

/// `WorkspaceSceneProviding` 的可控替身。
@MainActor
final class BranchStatusSceneProviding: WorkspaceSceneProviding {
    var currentScene: GitOKWorkspaceScene
    let availableScenes: [GitOKWorkspaceScene] = [.git, .banner, .icon]

    private var observers: [UUID: (WorkspaceSceneEvent) -> Void] = [:]
    private(set) var observerCount = 0

    init(currentScene: GitOKWorkspaceScene = .git) {
        self.currentScene = currentScene
    }

    func selectScene(_ scene: GitOKWorkspaceScene) {
        guard scene != currentScene else { return }
        let from = currentScene
        currentScene = scene
        let event = WorkspaceSceneEvent.sceneChanged(from: from, to: scene)
        for callback in observers.values { callback(event) }
    }

    func addObserver(
        _ callback: @escaping (WorkspaceSceneEvent) -> Void
    ) -> any WorkspaceSceneObserverHandle {
        let id = UUID()
        observers[id] = callback
        observerCount += 1
        return BranchStatusSceneHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
            self?.observerCount -= 1
        }
    }
}

@MainActor
final class BranchStatusSceneHandle: WorkspaceSceneObserverHandle {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() { onCancel() }
}
