import Foundation
import KitGit
import ProviderGitRepositoryWatch
import ProviderProjects

/// `ProjectProviding` 的可控替身。
///
/// 插件的 `onBoot` 只读取 `currentProject` 并订阅项目变化，因此替身只需要
/// 提供当前项目、记录订阅并允许测试手动派发事件。
@MainActor
final class WatchProjectsStub: ProjectProviding {
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
        return WatchProjectHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
            self?.observerCount -= 1
        }
    }

    /// 手动派发项目事件。
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

/// `ProjectProvidingObserverHandle` 的可取消句柄。
@MainActor
final class WatchProjectHandle: ProjectProvidingObserverHandle {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() { onCancel() }
}

/// `GitRepositoryWatching` 的可控替身：用于验证插件对仓库监听事件的接线。
@MainActor
final class WatchRepositoryStub: GitRepositoryWatching {
    private(set) var watchingRepositoryURL: URL?
    private var observers: [UUID: (GitRepositoryWatchingEvent) -> Void] = [:]
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func addObserver(
        _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
    ) -> any GitRepositoryWatchingObserverHandle {
        let id = UUID()
        observers[id] = callback
        return WatchRepositoryHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    func startWatching(repositoryURL: URL) {
        watchingRepositoryURL = repositoryURL
        startCount += 1
    }

    func stopWatching() {
        watchingRepositoryURL = nil
        stopCount += 1
    }

    /// 手动派发仓库监听事件。
    func send(_ event: GitRepositoryWatchingEvent) {
        for callback in observers.values {
            callback(event)
        }
    }
}

/// `GitRepositoryWatchingObserverHandle` 的可取消句柄。
@MainActor
final class WatchRepositoryHandle: GitRepositoryWatchingObserverHandle {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() { onCancel() }
}
