import Foundation
import KitGit

/// Provider 层的工作区快照单飞缓存。
///
/// 左侧状态摘要和右侧文件列表经常在相邻的 run loop 中同时请求同一仓库。
/// 这里让它们共享一次扫描，并保留一个很短的结果窗口，让用户点击工作区
/// 状态时可以立即拿到刚刚由摘要读取出的快照。真正的数据变更由观察者显式
/// 调用 invalidate；缓存窗口只是防止同一事件链里的重复读取。
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
        let date: Date
    }

    private let lock = NSLock()
    private let freshness: TimeInterval = 2
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
               Date().timeIntervalSince(value.date) < freshness {
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
                        date: Date()
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
        cached.removeValue(forKey: key)
        lock.unlock()
    }
}
