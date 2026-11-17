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
///
/// 调度策略（GitOK issue #18）：
/// 预热的目的是让快照缓存保持温热，从而让工作区视图切换项目时能立刻显示
/// 内容（`cachedWorktreeSnapshot` 直接返回上一次快照）。
///
/// ProviderGit 的快照缓存只有 2 秒的新鲜期、却有 30 分钟的保留期，因此
/// 「每次项目事件都重扫全部仓库」既昂贵又没有收益：
/// - 扫描本身是 libgit2 的全量工作区遍历，仓库多时叠加起来非常可观；
/// - 缓存里本来就有一份可用快照，重扫只是把同样的数据再写一遍；
/// - 更关键的是，用户切到某个仓库时，视图自己会发起一次加载
///   （ProviderGit 是 single-flight 的），预热那一轮并没有替视图省掉等待。
///
/// 因此本调度器记录每个仓库「上次预热的时间」：
/// - **当前项目**每次都预热（用户正要打开的就是它，代价只有一次扫描）；
/// - **其余仓库**只在「从未预热」或「预热已超过 `refreshInterval`」时才重扫，
///   默认间隔 5 分钟——落在快照缓存的保留期内，切换时仍能立刻显示缓存内容；
/// - 仓库被 `gitWatch` 报告变化时立即作废，下次必定重扫。
@MainActor
final class WorktreeSnapshotPreheater {
    private let projects: any ProjectProviding
    private let loadSnapshot: @Sendable (URL, GitProcessCancellation) throws -> Void
    private let invalidateSnapshot: @Sendable (URL) -> Void
    private let gitWatch: (any GitRepositoryWatching)?

    /// 仓库路径 → 上次预热完成的时间。
    private var warmedAt: [String: Date] = [:]

    /// 非当前仓库两次预热之间的最小间隔（秒）。
    private let refreshInterval: TimeInterval

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
        gitWatch: (any GitRepositoryWatching)?,
        refreshInterval: TimeInterval = 300
    ) {
        self.projects = projects
        self.loadSnapshot = loadSnapshot
        self.invalidateSnapshot = invalidateSnapshot
        self.gitWatch = gitWatch
        self.refreshInterval = max(0, refreshInterval)
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
        warmedAt.removeAll()
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
            invalidate(url)
            requestRefresh(preferredURL: url)
        case .stopped:
            break
        case .headChanged, .indexChanged, .stashChanged, .refsChanged, .workingTreeChanged:
            refreshCurrentProject()
        }
    }

    private func refreshCurrentProject() {
        guard let url = projects.currentProject?.url else { return }
        invalidate(url)
        requestRefresh(preferredURL: url)
    }

    /// 作废某个仓库的预热记录（下次必定重新扫描）。
    private func invalidate(_ url: URL) {
        warmedAt.removeValue(forKey: url.standardizedFileURL.path)
        invalidateSnapshot(url)
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
        let preferred = requestedPreferredURL
        requestedPreferredURL = nil

        let allURLs = WorktreeSnapshotPreheatPlan.orderedURLs(
            projects: projects.projects,
            preferredURL: preferred
        )

        // 只预热「当前项目」以及「从未预热 / 预热已过期」的仓库：
        // 缓存仍在保留期内的仓库重新扫描没有收益，却会让每次打开项目
        // 都重扫整个仓库列表。
        let urls = allURLs.filter { url in
            if url.path == preferred?.path { return true }
            guard let warmed = warmedAt[url.path] else { return true }
            return Date().timeIntervalSince(warmed) >= refreshInterval
        }

        guard !urls.isEmpty else { return }

        worker?.cancel()
        cancellation?.cancel()

        let token = GitProcessCancellation()
        cancellation = token
        let loadSnapshot = self.loadSnapshot

        // 单 worker 保证预热不会和当前用户操作争抢过多 CPU / 磁盘；
        // 当前项目通过队首优先完成，其余项目依次填充同一份 ProviderGit 缓存。
        worker = Task.detached(priority: .utility) { [weak self] in
            var completed: [(String, Date)] = []
            for url in urls {
                guard !token.isCancelled else { return }
                guard FileManager.default.fileExists(atPath: url.path) else { continue }

                do {
                    try loadSnapshot(url, token)
                    completed.append((url.path, Date()))
                } catch is CancellationError {
                    return
                } catch {
                    // 单个项目不可读不应阻塞其他项目的预热。
                    continue
                }
            }
            // 记录本轮完成的仓库；被取消的轮次结果已经过期，不再记录。
            guard !token.isCancelled else { return }
            await self?.recordWarmed(completed)
        }
    }

    /// 记录本轮预热完成的仓库。
    private func recordWarmed(_ completed: [(String, Date)]) {
        for (path, date) in completed {
            warmedAt[path] = date
        }
    }
}
