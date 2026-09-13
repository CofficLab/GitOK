import Foundation
import KitGit
import os
import ProviderActivityHeatmap
import ProviderGit

/// Plugin-owned local Git implementation of the shared activity data contract.
///
/// This type deliberately contains no SwiftUI code. It reads the current
/// repository, filters to the one-year history window, and persists snapshots
/// below this plugin's own storage directory.
@MainActor
final class LocalActivityHeatmapProvider: ActivityHeatmapProviding {
    private nonisolated static let historyMonths = 12
    private nonisolated static let logger = Logger(
        subsystem: "com.coffic.gitok.plugin.activity-heatmap",
        category: "LocalActivityHeatmapProvider"
    )

    typealias CommitLoader = @Sendable (URL, Int, Int) throws -> [GitCommit]
    typealias CancellableCommitLoader = @Sendable (URL, Int, Int, GitProcessCancellation?) throws -> [GitCommit]

    private nonisolated static let cacheFileName = "activity-heatmap.json"
    // Keep Git CLI output below the process pipe buffer. GitCommitLoader waits
    // for the process before reading stdout, so oversized pages can deadlock
    // before a snapshot is published.
    private nonisolated static let pageSize = 50

    private let directory: URL
    private let loadCommits: CancellableCommitLoader
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private var refreshToken = 0
    private var refreshTask: Task<Void, Never>?
    private var refreshCancellation: GitProcessCancellation?
    private var observers: [WeakObserver] = []

    private(set) var currentSnapshot: ActivityHeatmapSnapshot?
    private(set) var isLoading = false

    init(
        directory: URL,
        git: (any GitProviding)? = nil,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init,
        commitLoader: CommitLoader? = nil,
        cancellableCommitLoader: CancellableCommitLoader? = nil
    ) {
        self.directory = directory
        self.calendar = calendar
        self.now = now
        if let cancellableCommitLoader {
            self.loadCommits = cancellableCommitLoader
        } else if let commitLoader {
            self.loadCommits = { repository, limit, offset, _ in
                try commitLoader(repository, limit, offset)
            }
        } else {
            self.loadCommits = { [git] repository, limit, offset, cancellation in
                guard let git else { throw GitProviderError.noBackendAvailable }
                return try git.loadAllCommits(
                    in: repository,
                    limit: limit,
                    offset: offset,
                    cancellation: cancellation
                )
            }
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func refresh(for repository: URL?) {
        refreshTask?.cancel()
        refreshTask = nil
        refreshCancellation?.cancel()
        refreshCancellation = nil
        refreshToken &+= 1
        let token = refreshToken
        let standardizedRepository = repository?.standardizedFileURL

        guard let repository = standardizedRepository else {
            setSnapshot(nil)
            setLoading(false)
            return
        }

        // 项目可能已被用户在 Finder 中移动或删除。不要为失效路径启动
        // Git 查询；否则切换项目时旧任务会持续失败并制造无意义的 loading。
        guard FileManager.default.fileExists(atPath: repository.path) else {
            setSnapshot(nil)
            setLoading(false)
            return
        }

        let cachedSnapshot = loadCachedSnapshot(for: repository)
        setSnapshot(cachedSnapshot)
        // A cached snapshot is already useful to the UI. Keep it visible and
        // refresh silently in the background; only the first uncached load
        // needs a visible loading state.
        setLoading(cachedSnapshot == nil)
        let loadCommits = self.loadCommits
        let calendar = self.calendar
        let now = self.now()
        let cancellation = GitProcessCancellation(forceKillAfter: 1)
        refreshCancellation = cancellation
        refreshTask = Task.detached(priority: .utility) {
            let result: RefreshResult
            do {
                // 工作区是否有未提交变更不影响提交活跃度统计：
                // 有变更时同样生成热力图快照。
                let commits = try Self.loadRecentCommits(
                    in: repository,
                    now: now,
                    calendar: calendar,
                    loadCommits: loadCommits,
                    cancellation: cancellation
                )
                result = RefreshResult(
                    snapshot: Self.makeSnapshot(
                        repository: repository,
                        commits: commits,
                        calendar: calendar,
                        now: now
                    )
                )
            } catch is CancellationError {
                return
            } catch {
                // Preserve a cached snapshot on transient Git failures. The
                // provider has no fresh status to prove that it is displayable,
                // so a failure does not publish new data.
                Self.logger.error(
                    "Activity heatmap refresh failed for \(repository.path, privacy: .public): \(error.localizedDescription, privacy: .public)"
                )
                await self.finishLoading(token: token)
                return
            }
            await self.apply(result, token: token)
        }
    }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ActivityHeatmapEvent) -> Void
    ) -> any ActivityHeatmapObserverHandle {
        let handle = ObserverHandle(owner: self, callback: callback)
        observers.append(WeakObserver(handle))
        return handle
    }

    func setSnapshot(_ snapshot: ActivityHeatmapSnapshot?) {
        guard currentSnapshot != snapshot else { return }
        currentSnapshot = snapshot
        observers.removeAll { $0.handle == nil }
        for observer in observers {
            observer.handle?.invoke(.snapshotChanged)
        }
    }

    func setLoading(_ isLoading: Bool) {
        guard self.isLoading != isLoading else { return }
        self.isLoading = isLoading
        observers.removeAll { $0.handle == nil }
        for observer in observers {
            observer.handle?.invoke(.loadingChanged)
        }
    }

    private func apply(
        _ result: RefreshResult,
        token: Int
    ) async {
        guard token == refreshToken else { return }
        refreshTask = nil
        refreshCancellation = nil
        if let snapshot = result.snapshot {
            persist(snapshot)
            setSnapshot(snapshot)
        } else {
            setSnapshot(nil)
        }
        setLoading(false)
    }

    private func finishLoading(token: Int) {
        guard token == refreshToken else { return }
        refreshTask = nil
        refreshCancellation = nil
        setLoading(false)
    }

    // MARK: - Aggregation

    nonisolated private static func loadRecentCommits(
        in repository: URL,
        now: Date,
        calendar: Calendar,
        loadCommits: CancellableCommitLoader,
        cancellation: GitProcessCancellation
    ) throws -> [GitCommit] {
        guard let cutoff = calendar.date(byAdding: .month, value: -historyMonths, to: now) else { return [] }

        var offset = 0
        var commits: [GitCommit] = []
        while true {
            if cancellation.isCancelled { throw CancellationError() }
            let page = try loadCommits(repository, pageSize, offset, cancellation)
            if cancellation.isCancelled { throw CancellationError() }
            commits.append(contentsOf: page.filter { $0.date >= cutoff })
            offset += page.count
            if page.isEmpty || page.count < pageSize || page.contains(where: { $0.date < cutoff }) {
                break
            }
        }
        return commits
    }

    nonisolated static func makeSnapshot(
        repository: URL,
        commits: [GitCommit],
        calendar: Calendar,
        now: Date,
        generatedAt: Date? = nil
    ) -> ActivityHeatmapSnapshot {
        let counts = commits.reduce(into: [Date: Int]()) { result, commit in
            result[calendar.startOfDay(for: commit.date), default: 0] += 1
        }
        return ActivityHeatmapSnapshot(
            repositoryPath: repository.standardizedFileURL.path,
            generatedAt: generatedAt ?? now,
            days: counts.map { ActivityHeatmapDay(date: $0.key, commitCount: $0.value) }
        )
    }

    // MARK: - Cache

    private func cacheURL(for repository: URL) -> URL {
        let encodedPath = Data(repository.standardizedFileURL.path.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
        return directory
            .appendingPathComponent(encodedPath, isDirectory: true)
            .appendingPathComponent(Self.cacheFileName, isDirectory: false)
    }

    private func loadCachedSnapshot(for repository: URL) -> ActivityHeatmapSnapshot? {
        let url = cacheURL(for: repository)
        guard let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(ActivityHeatmapSnapshot.self, from: data),
              snapshot.repositoryPath == repository.standardizedFileURL.path else { return nil }
        return snapshot
    }

    private func persist(_ snapshot: ActivityHeatmapSnapshot) {
        let url = cacheURL(for: URL(fileURLWithPath: snapshot.repositoryPath))
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
        } catch {
            // The in-memory snapshot remains useful when the cache is unavailable.
        }
    }

    private struct RefreshResult: Sendable {
        let snapshot: ActivityHeatmapSnapshot?
    }

    private func removeObserver(_ handle: ObserverHandle) {
        observers.removeAll { $0.handle === handle }
    }

    @MainActor
    private final class ObserverHandle: ActivityHeatmapObserverHandle {
        private weak var owner: LocalActivityHeatmapProvider?
        private let callback: (ActivityHeatmapEvent) -> Void
        private var isCancelled = false

        init(
            owner: LocalActivityHeatmapProvider,
            callback: @escaping (ActivityHeatmapEvent) -> Void
        ) {
            self.owner = owner
            self.callback = callback
        }

        func cancel() {
            guard !isCancelled else { return }
            isCancelled = true
            owner?.removeObserver(self)
        }

        func invoke(_ event: ActivityHeatmapEvent) {
            guard !isCancelled else { return }
            callback(event)
        }
    }

    @MainActor
    private final class WeakObserver {
        weak var handle: ObserverHandle?

        init(_ handle: ObserverHandle) {
            self.handle = handle
        }
    }
}
