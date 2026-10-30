import Foundation
import KitGit

/// Provider 层的工作区快照单飞缓存。
///
/// 左侧状态摘要、右侧文件列表和工作区干净视图经常在相邻的 run loop 中同时请求
/// 同一仓库。这里让它们共享一次扫描，并保留最近完成的快照，让项目切换时可以
/// 立即展示上一次结果，同时在后台获取最新状态。真正的数据变更由观察者显式调用
/// invalidate；失效只会让快照不能被新的 load 复用，不会马上丢弃它，以支持
/// stale-while-revalidate。
final class WorktreeSnapshotStore: @unchecked Sendable {
    private final class Pending: @unchecked Sendable {
        let group = DispatchGroup()
        let generation: UInt64

        init(generation: UInt64) {
            self.generation = generation
            group.enter()
        }
    }

    private struct Cached {
        let snapshot: GitWorktreeSnapshot
        let generation: UInt64
        let updatedAt: Date
        /// 扫描序号：单调递增，用于判断「等待期间是否已经有新的扫描完成」。
        let sequence: UInt64
    }

    private let lock = NSLock()
    /// Fresh reads can be reused by another caller without starting a scan.
    private let freshness: TimeInterval = 2
    /// Keep a stale snapshot long enough to make project switching responsive.
    /// The cache remains in memory only and is discarded with the provider.
    private let staleRetention: TimeInterval = 30 * 60
    /// Upper bound of rescans caused by concurrent invalidations. A repository
    /// that keeps changing while we scan must not turn into an endless loop.
    private let maxRescans = 3
    private var generations: [String: UInt64] = [:]
    private var cached: [String: Cached] = [:]
    private var pending: [String: Pending] = [:]
    /// 已完成扫描的序号（单调递增）。
    private var scanSequence: UInt64 = 0

    /// Loads the current worktree snapshot for `repository`.
    ///
    /// - Parameters:
    ///   - force: Skip the freshness window and always collect a new snapshot.
    ///     The previously cached snapshot stays available through
    ///     ``cached(repository:)`` so the UI can keep showing it meanwhile.
    ///   - loader: Performs the actual scan. It may run more than once when the
    ///     repository is invalidated while a scan is in flight.
    func load(
        repository: URL,
        force: Bool = false,
        cancellation: GitProcessCancellation? = nil,
        loader: () throws -> GitWorktreeSnapshot
    ) throws -> GitWorktreeSnapshot {
        let key = repository.standardizedFileURL.path
        var rescans = 0

        lock.lock()
        // 记录本次请求时的扫描序号：等待在途扫描期间完成的扫描同样算「最新
        // 数据」，强制刷新不必再扫一次（否则每个消费者都会重复扫描同一仓库）。
        let requestedSequence = scanSequence
        lock.unlock()

        while true {
            if cancellation?.isCancelled == true { throw CancellationError() }

            lock.lock()
            let generation = generations[key, default: 0]
            if let value = cached[key], value.generation == generation {
                let age = Date().timeIntervalSince(value.updatedAt)
                if !force, age < freshness {
                    lock.unlock()
                    return value.snapshot
                }
                if force, value.sequence > requestedSequence {
                    lock.unlock()
                    return value.snapshot
                }
            }

            if let current = pending[key] {
                lock.unlock()
                while current.group.wait(timeout: .now() + 0.05) == .timedOut {
                    if cancellation?.isCancelled == true { throw CancellationError() }
                }
                continue
            }

            let current = Pending(generation: generation)
            pending[key] = current
            lock.unlock()

            do {
                let snapshot = try loader()
                lock.lock()
                // The repository may have been invalidated while we were
                // scanning. That snapshot describes a state that no longer
                // holds, so it must not be handed out as the current one.
                let wasInvalidated = generations[key, default: 0] != generation
                if !wasInvalidated {
                    scanSequence &+= 1
                    cached[key] = Cached(
                        snapshot: snapshot,
                        generation: generation,
                        updatedAt: Date(),
                        sequence: scanSequence
                    )
                }
                if pending[key] === current {
                    pending.removeValue(forKey: key)
                }
                lock.unlock()
                current.group.leave()

                if wasInvalidated, rescans < maxRescans {
                    rescans += 1
                    continue
                }
                return snapshot
            } catch {
                lock.lock()
                if pending[key] === current {
                    pending.removeValue(forKey: key)
                }
                lock.unlock()
                current.group.leave()
                throw error
            }
        }
    }

    func invalidate(repository: URL) {
        let key = repository.standardizedFileURL.path
        lock.lock()
        generations[key, default: 0] &+= 1
        lock.unlock()
    }

    /// Returns the most recent snapshot for immediate display, even after the
    /// repository was invalidated. Callers must start a normal `load` alongside
    /// this read when freshness matters.
    func cached(repository: URL) -> GitWorktreeSnapshot? {
        let key = repository.standardizedFileURL.path
        lock.lock()
        defer { lock.unlock() }
        guard let value = cached[key],
              Date().timeIntervalSince(value.updatedAt) < staleRetention else {
            return nil
        }
        return value.snapshot
    }
}
