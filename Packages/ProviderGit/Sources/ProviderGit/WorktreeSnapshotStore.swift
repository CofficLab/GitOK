import Foundation
import KitGit

/// Provider 层的工作区快照单飞缓存。
///
/// 左侧状态摘要和右侧文件列表经常在相邻的 run loop 中同时请求同一仓库。
/// 这里让它们共享一次扫描，并保留最近完成的快照，让项目切换时可以立即展示
/// 上一次结果，同时在后台获取最新状态。真正的数据变更由观察者显式调用
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
    }

    private let lock = NSLock()
    /// Fresh reads can be reused by another caller without starting a scan.
    private let freshness: TimeInterval = 2
    /// Keep a stale snapshot long enough to make project switching responsive.
    /// The cache remains in memory only and is discarded with the provider.
    private let staleRetention: TimeInterval = 30 * 60
    private var generations: [String: UInt64] = [:]
    private var cached: [String: Cached] = [:]
    private var pending: [String: Pending] = [:]

    func load(
        repository: URL,
        cancellation: GitProcessCancellation? = nil,
        loader: () throws -> GitWorktreeSnapshot
    ) throws -> GitWorktreeSnapshot {
        let key = repository.standardizedFileURL.path

        while true {
            if cancellation?.isCancelled == true { throw CancellationError() }

            lock.lock()
            let generation = generations[key, default: 0]
            if let value = cached[key],
               value.generation == generation,
               Date().timeIntervalSince(value.updatedAt) < freshness {
                lock.unlock()
                return value.snapshot
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
                if generations[key, default: 0] == generation {
                    cached[key] = Cached(
                        snapshot: snapshot,
                        generation: generation,
                        updatedAt: Date()
                    )
                }
                if pending[key] === current {
                    pending.removeValue(forKey: key)
                }
                lock.unlock()
                current.group.leave()
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
