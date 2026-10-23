import Foundation
import KitGit
import Testing
@testable import ProviderGit

@Suite("WorktreeSnapshotStore")
struct WorktreeSnapshotStoreTests {
    @Test("Invalidation preserves the latest snapshot for immediate display")
    func invalidationPreservesLatestSnapshot() throws {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-snapshot-tests")
        let snapshot = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "README.md", stagedStatus: " ", worktreeStatus: "M")],
            branch: "main"
        )

        _ = try store.load(repository: repository) { snapshot }
        store.invalidate(repository: repository)

        #expect(store.cached(repository: repository) == snapshot)
    }

    @Test("A stale snapshot is not used as the result of a fresh load")
    func staleSnapshotDoesNotSatisfyLoad() throws {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-snapshot-tests")
        let previous = GitWorktreeSnapshot(entries: [], branch: "main")
        let current = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "Sources/App.swift", stagedStatus: "M", worktreeStatus: " ")],
            branch: "main"
        )

        _ = try store.load(repository: repository) { previous }
        store.invalidate(repository: repository)
        let loaded = try store.load(repository: repository) { current }

        #expect(loaded == current)
        #expect(store.cached(repository: repository) == current)
    }

    /// 复现：扫描进行期间仓库状态被作废（提交 / 外部改动触发了 invalidate），
    /// 这次扫描得到的结果描述的是已经过期的状态。快照中枢不能把它当作
    /// 「当前结果」交给调用方，否则变更列表会显示一份已经失效的文件清单
    /// （状态条与列表对不上、列表整块空白）。
    @Test("A snapshot invalidated while scanning is rescanned instead of returned")
    func invalidatedScanIsRescanned() throws {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-invalidated-scan")
        let stale = GitWorktreeSnapshot(entries: [], branch: "main")
        let fresh = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "App/Info.plist", stagedStatus: " ", worktreeStatus: "M")],
            branch: "main"
        )

        var scanCount = 0
        let loaded = try store.load(repository: repository) {
            scanCount += 1
            if scanCount == 1 {
                // 扫描途中仓库被作废（模拟 watcher 触发的失效）。
                store.invalidate(repository: repository)
                return stale
            }
            return fresh
        }

        #expect(scanCount == 2, "作废后的扫描必须重扫，不能把过期结果当作当前结果")
        #expect(loaded == fresh)
        #expect(store.cached(repository: repository) == fresh)
    }

    /// 强制刷新必须真的重新扫描，但同时保留上一份快照供界面立即展示，
    /// 这样状态条 / 干净概览不会因为别人刷新而把数据清空。
    @Test("Forced refresh rescans without dropping the previously cached snapshot")
    func forcedRefreshRescansAndKeepsDisplaySnapshot() throws {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-force-refresh")
        let first = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "README.md", stagedStatus: " ", worktreeStatus: "M")],
            branch: "main"
        )
        let second = GitWorktreeSnapshot(entries: [], branch: "main")

        var scanCount = 0
        _ = try store.load(repository: repository) {
            scanCount += 1
            return first
        }
        let refreshed = try store.load(repository: repository, force: true) {
            scanCount += 1
            return second
        }

        #expect(scanCount == 2)
        #expect(refreshed == second)
        #expect(store.cached(repository: repository) == second)
    }

    /// 新鲜度窗口内的普通读取必须复用缓存，避免同一仓库被反复扫描。
    @Test("A load inside the freshness window reuses the cached snapshot")
    func freshLoadReusesCachedSnapshot() throws {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-freshness")
        let snapshot = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "README.md", stagedStatus: " ", worktreeStatus: "M")],
            branch: "main"
        )

        var scanCount = 0
        _ = try store.load(repository: repository) {
            scanCount += 1
            return snapshot
        }
        let reused = try store.load(repository: repository) {
            scanCount += 1
            return snapshot
        }

        #expect(scanCount == 1)
        #expect(reused == snapshot)
    }

    /// 强制刷新如果是在等待一次在途扫描，就直接复用那次扫描的结果，
    /// 不能再扫一遍——否则状态条 / 变更列表 / 干净概览每个消费者都会重复
    /// 扫描同一个仓库，把启动拖慢好几秒。
    @Test("A forced refresh that waited for an in-flight scan does not scan twice")
    func forcedRefreshReusesInFlightScan() throws {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-force-inflight")
        let snapshot = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "README.md", stagedStatus: " ", worktreeStatus: "M")],
            branch: "main"
        )

        let counter = ScanCounter()
        let gate = DispatchSemaphore(value: 0)
        let scanner = Thread {
            _ = try? store.load(repository: repository) {
                counter.increment()
                gate.wait()
                return snapshot
            }
        }
        scanner.start()
        // 扫描在后台阻塞一小段时间后自行完成：强制刷新会等待这次在途扫描。
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3) {
            gate.signal()
        }

        // 等扫描真正进入 pending，再发起强制刷新。
        let deadline = Date().addingTimeInterval(2)
        while counter.value == 0, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.01)
        }
        let refreshed = try store.load(repository: repository, force: true) {
            counter.increment()
            return snapshot
        }

        #expect(refreshed == snapshot)
        #expect(counter.value == 1, "等待在途扫描完成后不应再扫一次")
    }
}

/// 跨线程记录扫描次数。
private final class ScanCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }
}

extension WorktreeSnapshotStoreTests {
    @Test("Cancellation before load throws CancellationError")
    func cancellationBeforeLoadThrows() {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-cancel")
        let cancellation = GitProcessCancellation()
        cancellation.cancel()

        #expect(throws: CancellationError.self) {
            try store.load(repository: repository, cancellation: cancellation) {
                GitWorktreeSnapshot(entries: [], branch: "main")
            }
        }
    }

    @Test("Cached returns nil for unknown repository")
    func cachedUnknownReturnsNil() {
        let store = WorktreeSnapshotStore()
        #expect(store.cached(repository: URL(fileURLWithPath: "/tmp/never-loaded")) == nil)
    }

    @Test("Loader error propagates and pending is cleared")
    func loaderErrorPropagates() {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-error")

        enum TestError: Error { case boom }
        #expect(throws: TestError.self) {
            try store.load(repository: repository) { throw TestError.boom }
        }

        // After error, pending is cleared; next call starts fresh
        let snapshot = try? store.load(repository: repository) {
            GitWorktreeSnapshot(entries: [], branch: "main")
        }
        #expect(snapshot?.branch == "main")
    }
}
