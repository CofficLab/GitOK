import Foundation
import KitGit
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects

/// 负责把项目列表转换为后台工作区快照任务。
///
/// 关注点边界：
/// - `ProjectProviding` 只提供项目列表与项目事件；
/// - `GitProviding` 只负责读取 / 缓存 Git 快照；
/// - 本类型只负责排序、取消和后台调度，不向 UI 暴露状态。
@MainActor
final class WorktreeSnapshotPreheater {
    private let projects: any ProjectProviding
    private let loadSnapshot: @Sendable (URL, GitProcessCancellation) throws -> Void
    private let invalidateSnapshot: @Sendable (URL) -> Void
    private let gitWatch: (any GitRepositoryWatching)?

    private var projectsHandle: (any ProjectProvidingObserverHandle)?
    private var gitWatchHandle: (any GitRepositoryWatchingObserverHandle)?
    private var refreshRequest: Task<Void, Never>?
    private var worker: Task<Void, Never>?
    private var cancellation: GitProcessCancellation?
    private var requestedPreferredURL: URL?

    init(
        projects: any ProjectProviding,
        loadSnapshot: @escaping @Sendable (URL, GitProcessCancellation) throws -> Void,
        invalidateSnapshot: @escaping @Sendable (URL) -> Void,
        gitWatch: (any GitRepositoryWatching)?
    ) {
        self.projects = projects
        self.loadSnapshot = loadSnapshot
        self.invalidateSnapshot = invalidateSnapshot
        self.gitWatch = gitWatch
    }

    func start() {
        projectsHandle = projects.addObserver { [weak self] event in
            self?.handle(event)
        }

        if let gitWatch {
            gitWatchHandle = gitWatch.addObserver { [weak self] event in
                self?.handle(event)
            }
        }

        requestRefresh(preferredURL: projects.currentProject?.url)
    }

    func stop() {
        projectsHandle?.cancel()
        projectsHandle = nil
        gitWatchHandle?.cancel()
        gitWatchHandle = nil
        refreshRequest?.cancel()
        refreshRequest = nil
        worker?.cancel()
        worker = nil
        cancellation?.cancel()
        cancellation = nil
        requestedPreferredURL = nil
    }

    private func handle(_ event: ProjectProvidingEvent) {
        switch event {
        case .projectsChanged, .selectionChanged:
            requestRefresh(preferredURL: projects.currentProject?.url)
        case .dataChanged:
            refreshCurrentProject()
        case .commitSelectionChanged, .currentFileChanged:
            break
        }
    }

    private func handle(_ event: GitRepositoryWatchingEvent) {
        switch event {
        case .started(let url):
            invalidateSnapshot(url)
            requestRefresh(preferredURL: url)
        case .stopped:
            break
        case .headChanged, .indexChanged, .stashChanged, .refsChanged, .workingTreeChanged:
            refreshCurrentProject()
        }
    }

    private func refreshCurrentProject() {
        guard let url = projects.currentProject?.url else { return }
        invalidateSnapshot(url)
        requestRefresh(preferredURL: url)
    }

    /// 合并同一轮事件（例如打开项目同时产生 projectsChanged 和
    /// selectionChanged），避免重复取消并重建后台任务。
    private func requestRefresh(preferredURL: URL?) {
        requestedPreferredURL = preferredURL?.standardizedFileURL
        refreshRequest?.cancel()
        refreshRequest = Task { @MainActor [weak self] in
            await Task.yield()
            guard !Task.isCancelled else { return }
            self?.startWorker()
        }
    }

    private func startWorker() {
        refreshRequest = nil
        let urls = WorktreeSnapshotPreheatPlan.orderedURLs(
            projects: projects.projects,
            preferredURL: requestedPreferredURL
        )
        requestedPreferredURL = nil

        worker?.cancel()
        cancellation?.cancel()

        let token = GitProcessCancellation()
        cancellation = token
        let loadSnapshot = self.loadSnapshot

        // 单 worker 保证预热不会和当前用户操作争抢过多 CPU / 磁盘；
        // 当前项目通过队首优先完成，其余项目依次填充同一份 ProviderGit 缓存。
        worker = Task.detached(priority: .utility) {
            for url in urls {
                guard !token.isCancelled else { return }
                guard FileManager.default.fileExists(atPath: url.path) else { continue }

                do {
                    try loadSnapshot(url, token)
                } catch is CancellationError {
                    return
                } catch {
                    // 单个项目不可读不应阻塞其他项目的预热。
                    continue
                }
            }
        }
    }
}
