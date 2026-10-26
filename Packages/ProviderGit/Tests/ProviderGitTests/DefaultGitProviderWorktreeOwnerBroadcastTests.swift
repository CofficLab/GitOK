import Foundation
import KitGit
import Testing
@testable import ProviderGit

/// 归属广播的跨仓库语义（用真实的 `DefaultGitProvider` 验证）。
///
/// 这组测试锁定的是**广播契约**本身：
/// `WorktreeContentOwner` 按仓库发布，但**推送给所有订阅者**。订阅者因此
/// 必须自己过滤出「说的是当前项目」的那一条。
///
/// 线上后果：后台预热插件（`PluginGitWorktreePreheat`）会依次扫描侧边栏里的
/// 每一个项目，每次扫描结束都会发布一次归属结论。如果订阅方不做仓库过滤，
/// 别的项目的结论就会串台覆盖当前项目——
///
/// - 当前项目是脏的，被别的干净项目覆盖成 `.clean`
///   → 变更列表渲染 `EmptyView()` 不占布局
///   → 主内容区塌陷，提交表单漂到面板中间。
///
/// 这个测试文件本身是**通过**的（它描述的是正确的广播契约）；
/// 真正缺失的是订阅方的过滤——那条断言在 `PluginCommitDetail` 的
/// `CommitDetailWorktreeOwnerIsolationTests` 里。
@Suite("DefaultGitProvider worktree owner broadcast")
@MainActor
struct DefaultGitProviderWorktreeOwnerBroadcastTests {
    /// 观察者收到的所有 (仓库, 结论) 事件。
    private final class EventBox: @unchecked Sendable {
        private let lock = NSLock()
        private var storage: [(URL, WorktreeContentOwner)] = []

        var events: [(URL, WorktreeContentOwner)] {
            lock.lock()
            defer { lock.unlock() }
            return storage
        }

        func append(_ event: (URL, WorktreeContentOwner)) {
            lock.lock()
            storage.append(event)
            lock.unlock()
        }
    }

    /// 扫描一次仓库并发布归属结论（等价于生产环境里
    /// `DefaultGitProvider.loadWorktreeSnapshot` 末尾的 `publishWorktreeOwner`）。
    private func scan(
        provider: DefaultGitProvider,
        backend: ScriptedGitBackend,
        repository: URL,
        entries: [GitStatusEntry]
    ) throws {
        backend.handlers["loadWorktreeSnapshot"] = { _ in
            GitWorktreeSnapshot(entries: entries, branch: "main")
        }
        backend.handlers["loadEntries"] = { _ in entries }
        backend.handlers["loadStatus"] = { _ in
            GitWorktreeStatus(isClean: entries.isEmpty, changeCount: entries.count, branch: "main")
        }
        _ = try provider.loadWorktreeSnapshot(in: repository)
    }

    @Test("Scanning a second repository broadcasts its verdict to every observer")
    func secondRepositoryBroadcastReachesAllObservers() throws {
        let provider = DefaultGitProvider()
        let backend = ScriptedGitBackend.makeBackend(id: "test.backend", priority: 10)
        try provider.registerBackend(backend)

        let dirtyRepository = URL(fileURLWithPath: "/tmp/gitok-owner-dirty")
        let cleanRepository = URL(fileURLWithPath: "/tmp/gitok-owner-clean")
        let received = EventBox()

        let handle = provider.addWorktreeContentOwnerObserver { url, owner in
            received.append((url, owner))
        }
        defer { handle.cancel() }

        // 当前项目：脏。
        try scan(
            provider: provider,
            backend: backend,
            repository: dirtyRepository,
            entries: [GitStatusEntry(path: "a.xcstrings", stagedStatus: " ", worktreeStatus: "M")]
        )
        // 后台预热扫描了另一个干净项目。
        try scan(
            provider: provider,
            backend: backend,
            repository: cleanRepository,
            entries: []
        )

        // 广播契约：两条结论都推给了同一个订阅者，且带上了仓库身份。
        let events = received.events
        #expect(events.count == 2)
        #expect(events.first?.0 == dirtyRepository)
        #expect(events.first?.1 == .changes)
        #expect(events.last?.0 == cleanRepository)
        #expect(events.last?.1 == .clean)

        // 结论按仓库分别保存，查询某个仓库不会拿到别的仓库的结论。
        #expect(provider.worktreeContentOwner(for: dirtyRepository) == .changes)
        #expect(provider.worktreeContentOwner(for: cleanRepository) == .clean)
    }

    @Test("Rescanning the same repository with the same verdict does not rebroadcast")
    func unchangedVerdictIsNotRebroadcast() throws {
        let provider = DefaultGitProvider()
        let backend = ScriptedGitBackend.makeBackend(id: "test.backend", priority: 10)
        try provider.registerBackend(backend)

        let repository = URL(fileURLWithPath: "/tmp/gitok-owner-stable")
        let received = EventBox()

        let handle = provider.addWorktreeContentOwnerObserver { url, owner in
            received.append((url, owner))
        }
        defer { handle.cancel() }

        let entries = [GitStatusEntry(path: "a.xcstrings", stagedStatus: " ", worktreeStatus: "M")]
        try scan(provider: provider, backend: backend, repository: repository, entries: entries)
        try scan(provider: provider, backend: backend, repository: repository, entries: entries)

        // 结论没变就不重复通知——订阅方不会因为重复扫描而被反复唤醒。
        #expect(received.events.count == 1)
    }
}
