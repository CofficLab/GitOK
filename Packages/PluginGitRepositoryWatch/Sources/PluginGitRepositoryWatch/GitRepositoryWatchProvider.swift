import Foundation
import ProviderGitRepositoryWatch

/// `GitRepositoryWatching` 的真正实现。
///
/// 内部用两个 FSEventStream 监听器：
/// - `GitDirectoryWatcher` 监听 `.git` 目录，检测 git 内部状态变化；
/// - `WorkingTreeWatcher` 监听项目根目录，检测工作区文件变化。
///
/// 收到事件后 debounce 500ms：
/// - `.git` 变化：重新读取快照，按维度（HEAD / index / stash / refs）对比，广播对应事件；
/// - 工作区变化：广播 `.workingTreeChanged`（消费方如工作区状态条应重新计算变更文件数）。
///
/// 对齐旧版 `GitWatcherCoordinator`：
/// - 500ms debounce 合并突发事件（比如提交会同时改 HEAD + index + refs）；
/// - 仅在指纹真正变化时广播（避免 FSEventStream 噪音误触发）；
/// - 切换项目时自动 stop 旧 + start 新。
@MainActor
public final class GitRepositoryWatchProvider: GitRepositoryWatching {

    public private(set) var watchingRepositoryURL: URL?

    /// 实际监听的 `.git` 目录路径（解析 worktree 后）；未监听时为 nil。
    private var watchedGitDirectory: String?

    /// 上次快照，用于 diff；未监听时为 nil。
    private var lastSnapshot: GitDirectorySnapshot?

    /// FSEventStream 监听器（`.git` 目录）；未监听时为 nil。
    private var watcher: GitDirectoryWatcher?

    /// 工作区 FSEventStream 监听器（项目根目录）；未监听时为 nil。
    private var workingTreeWatcher: WorkingTreeWatcher?

    /// `.git` 目录 debounce 任务；每次 onChange 取消前一个并重建。
    private var debounceTask: Task<Void, Never>?

    /// 工作区 debounce 任务。
    private var workingTreeDebounceTask: Task<Void, Never>?

    /// 订阅方列表（拷贝后再遍历，避免回调内增删订阅导致迭代失效）。
    private var observers: [(id: UUID, callback: (GitRepositoryWatchingEvent) -> Void)] = []

    public init() {}

    // MARK: - Contract

    public func addObserver(
        _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
    ) -> any GitRepositoryWatchingObserverHandle {
        let id = UUID()
        observers.append((id, callback))
        return DefaultHandle { [weak self] in
            self?.observers.removeAll { $0.id == id }
        }
    }

    public func startWatching(repositoryURL: URL) {
        let standardized = repositoryURL.standardizedFileURL
        guard watchingRepositoryURL != standardized else { return }

        // 切换项目：先停旧的再启新的。
        if watchingRepositoryURL != nil {
            teardownWatcher(emitStoppedEvent: false)
        }

        do {
            let gitDirectory = try GitDirectoryResolver.resolveGitDirectory(for: standardized)
            let snapshot = GitDirectoryResolver.readSnapshot(gitDirectory: gitDirectory)

            self.watchedGitDirectory = gitDirectory.path
            self.lastSnapshot = snapshot
            self.watchingRepositoryURL = standardized

            // onChange 在 FSEventStream 的 utility 队列触发，
            // GitDirectoryWatcher 内部已派发回 MainActor，
            // 这里直接调度去抖检查。
            self.watcher = try GitDirectoryWatcher(url: gitDirectory) { [weak self] in
                self?.scheduleChangeCheck()
            }

            // 启动工作区监听（监听项目根目录，检测文件变化）
            self.workingTreeWatcher = try WorkingTreeWatcher(url: standardized) { [weak self] in
                self?.scheduleWorkingTreeChangeCheck()
            }

            broadcast(.started(repositoryURL: standardized))
        } catch {
            // 解析失败（非 git 仓库 / .git 不可读）→ 静默，不广播。
            // 上层可订阅 .stopped 判断监听是否活跃；或等下次项目切换再重试。
            watchingRepositoryURL = nil
            watchedGitDirectory = nil
            lastSnapshot = nil
        }
    }

    public func stopWatching() {
        guard watchingRepositoryURL != nil else { return }
        teardownWatcher(emitStoppedEvent: true)
    }

    // MARK: - Internal (for tests)

    /// 当前是否有活跃的 FSEventStream。
    var isWatcherActive: Bool { watcher != nil }

    /// 当前 `.git` 目录路径（测试用）。
    var watchedGitDirectoryPath: String? { watchedGitDirectory }

    // MARK: - Private

    private func teardownWatcher(emitStoppedEvent: Bool) {
        debounceTask?.cancel()
        debounceTask = nil
        watcher?.stop()
        watcher = nil
        workingTreeDebounceTask?.cancel()
        workingTreeDebounceTask = nil
        workingTreeWatcher?.stop()
        workingTreeWatcher = nil
        watchedGitDirectory = nil
        lastSnapshot = nil
        watchingRepositoryURL = nil
        if emitStoppedEvent {
            broadcast(.stopped)
        }
    }

    private func scheduleChangeCheck() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.checkForGitDirectoryChange()
        }
    }

    private func checkForGitDirectoryChange() {
        guard let watchedGitDirectory else { return }

        let gitDirectory = URL(fileURLWithPath: watchedGitDirectory, isDirectory: true)
        let currentSnapshot = GitDirectoryResolver.readSnapshot(gitDirectory: gitDirectory)
        let previousSnapshot = lastSnapshot

        let headChanged = currentSnapshot.head != previousSnapshot?.head
        let indexChanged = currentSnapshot.index != previousSnapshot?.index
        let stashChanged = currentSnapshot.stash != previousSnapshot?.stash
        let refsChanged = currentSnapshot.refs != previousSnapshot?.refs

        guard headChanged || indexChanged || stashChanged || refsChanged else { return }

        lastSnapshot = currentSnapshot

        // 按维度广播；多个维度同时变化时全部广播（消费方各自按需处理）。
        if headChanged {
            broadcast(.headChanged(
                previousHead: previousSnapshot?.head,
                head: currentSnapshot.head
            ))
        }
        if indexChanged {
            broadcast(.indexChanged)
        }
        if stashChanged {
            broadcast(.stashChanged)
        }
        if refsChanged {
            broadcast(.refsChanged)
        }
    }

    // MARK: - Working Tree

    /// 调度工作区变化检查（debounce 500ms）。
    ///
    /// 工作区变化不需要像 `.git` 目录那样做快照对比（文件太多，对比成本高），
    /// 直接广播 `.workingTreeChanged`，让消费方自行调用 `git status` 重算。
    private func scheduleWorkingTreeChangeCheck() {
        workingTreeDebounceTask?.cancel()
        workingTreeDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.broadcast(.workingTreeChanged)
        }
    }

    private func broadcast(_ event: GitRepositoryWatchingEvent) {
        let current = observers
        for observer in current {
            observer.callback(event)
        }
    }

    // MARK: - Handle

    private final class DefaultHandle: GitRepositoryWatchingObserverHandle {
        private let onCancel: () -> Void

        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }

        func cancel() {
            onCancel()
        }
    }
}
