import Foundation
import KitGit
import ProviderGit
import XCTest
@testable import PluginCommitDetail

/// `CommitFilePageStore` 的有界分页行为测试。
///
/// 使用内存 mock 后端（`MockGitProviding`）提供确定性的分页数据，避免真实
/// git 进程的时序干扰；覆盖计划 Task 3/5 要求：首页加载、去重、失败重试、
/// LRU 淘汰上界、commit 切换失效，以及大量文件下的内存有界性。
@MainActor
final class CommitFilePageStoreTests: XCTestCase {
    private enum MockError: Error {
        case failed
    }

    /// 最小 `GitProviding` mock：只有分页读取是真实的（内存切片），其余
    /// 方法为桩实现，供 `CommitFilePageStore` 在确定性环境下运行。
    ///
    /// 分页任务在 detached 并发下访问 mock 状态，因此用锁保护可变字段。
    private final class MockGitProviding: @unchecked Sendable, GitProviding {
        private let lock = NSLock()
        private var _changes: [GitFileChange] = []
        /// pageIndex → 剩余失败次数（用于重试测试）。
        private var _failCounts: [Int: Int] = [:]
        private var _pageLoadCounts: [Int: Int] = [:]
        private var _countCalls = 0

        var changes: [GitFileChange] {
            get { lock.lock(); defer { lock.unlock() }; return _changes }
            set { lock.lock(); defer { lock.unlock() }; _changes = newValue }
        }
        var failCounts: [Int: Int] {
            get { lock.lock(); defer { lock.unlock() }; return _failCounts }
            set { lock.lock(); defer { lock.unlock() }; _failCounts = newValue }
        }
        var pageLoadCounts: [Int: Int] {
            lock.lock(); defer { lock.unlock() }; return _pageLoadCounts
        }
        var countCalls: Int {
            lock.lock(); defer { lock.unlock() }; return _countCalls
        }

        func countCommitChanges(commit hash: String, in repository: URL) throws -> Int {
            lock.lock(); defer { lock.unlock() }
            _countCalls += 1
            return _changes.count
        }

        func loadCommitChangesPage(
            commit hash: String,
            limit: Int,
            offset: Int,
            in repository: URL
        ) throws -> GitFileChangePage {
            lock.lock(); defer { lock.unlock() }
            let pageIndex = offset / max(limit, 1)
            _pageLoadCounts[pageIndex, default: 0] += 1
            if let remaining = _failCounts[pageIndex], remaining > 0 {
                _failCounts[pageIndex] = remaining - 1
                throw MockError.failed
            }
            let start = min(max(offset, 0), _changes.count)
            let end = min(start + max(limit, 0), _changes.count)
            return GitFileChangePage(
                offset: offset,
                changes: Array(_changes[start..<end]),
                hasMore: end < _changes.count
            )
        }

        // MARK: - 桩实现（本测试不调用）

        func loadCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] { [] }
        func countCommits(in repository: URL) throws -> Int { 0 }
        func unpushedCommitHashes(in repository: URL) throws -> Set<String> { [] }
        func loadStatus(in repository: URL) throws -> GitWorktreeStatus {
            GitWorktreeStatus(isClean: true, changeCount: 0, branch: nil)
        }
        func loadEntries(in repository: URL) throws -> [GitStatusEntry] { [] }
        func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange] { [] }
        func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String { "" }
        func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String { "" }
        func currentBranch(in repository: URL) -> String? { nil }
        func latestTag(in repository: URL) -> String? { nil }
        func firstCommitDate(in repository: URL) -> Date? { nil }
        func unpushedCount(in repository: URL) -> Int? { nil }
        func hasRemotes(in repository: URL) -> Bool { false }
        func unpulledCount(in repository: URL) -> Int? { nil }
        func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus {
            GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
        }
        func listBranches(in repository: URL) throws -> [GitBranchSummary] { [] }
        func createBranch(named name: String, in repository: URL) throws {}
        func checkoutBranch(named name: String, in repository: URL) throws {}
        func deleteBranch(named name: String, in repository: URL) throws {}
        func renameBranch(from currentName: String, to newName: String, in repository: URL) throws {}
        func setUpstream(localBranch: String, upstreamBranch: String, in repository: URL) throws {}
        func unsetUpstream(localBranch: String, in repository: URL) throws {}
        func publishBranch(localBranch: String, remote: String, remoteBranch: String?, in repository: URL) throws {}
        func deleteRemoteBranch(named branchName: String, remote: String, in repository: URL) throws {}
        func compareBranches(base: String, head: String, in repository: URL) throws -> GitBranchCompare {
            GitBranchCompare(base: base, head: head, ahead: 0, behind: 0, commits: [], files: [])
        }
        func undoCommit(_ commitHash: String, parentHash: String, in repository: URL) throws -> String { "" }
        func revertCommit(_ commitHash: String, in repository: URL) throws -> String { "" }
        func softReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
        func mixedReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
        func hardReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
        func squash(to targetHash: String, parentHash: String, expectedHead: String, message: String, in repository: URL) throws -> String { "" }
        func createLightweightTag(named name: String, at commitHash: String, in repository: URL) throws -> String { "" }
        func createAnnotatedTag(named name: String, at commitHash: String, message: String, in repository: URL) throws -> String { "" }
        func deleteLocalTag(named name: String, in repository: URL) throws -> String { "" }
        func pushTag(named name: String, remote: String, in repository: URL) throws -> String { "" }
        func deleteRemoteTag(named name: String, remote: String, in repository: URL) throws -> String { "" }
        func listStashes(in repository: URL) -> [GitStashEntry] { [] }
        func hasChangesToStash(in repository: URL) -> Bool { false }
        func saveStash(message: String?, in repository: URL) throws {}
        func applyStash(_ entry: GitStashEntry, in repository: URL) throws {}
        func popStash(_ entry: GitStashEntry, in repository: URL) throws {}
        func dropStash(_ entry: GitStashEntry, in repository: URL) throws {}
        func cherryPickStatus(in repository: URL) -> GitCherryPickStatus { .inactive }
        func cherryPick(commits: [String], onto branch: String?, in repository: URL) throws -> String { "" }
        func continueCherryPick(in repository: URL) throws -> String { "" }
        func abortCherryPick(in repository: URL) throws -> String { "" }
        func listSubmodules(in repository: URL) -> [GitSubmoduleSummary] { [] }
        func updateSubmodules(in repository: URL) throws {}
        func validateCloneDestination(_ destination: URL) throws {}
        func defaultRepositoryName(from remoteURL: String) -> String? { nil }
        func clone(remoteURL: String, destination: URL) throws -> URL {
            throw GitProviderError.backendOperationUnsupported("clone")
        }
        func hasStagedChanges(in repository: URL) throws -> Bool { false }
        func addAll(in repository: URL) throws {}
        func stageFiles(_ filePaths: [String], in repository: URL) throws {}
        func unstageFiles(_ filePaths: [String], in repository: URL) throws {}
        func discardFileChanges(_ filePath: String, in repository: URL) throws {}
        func discardFiles(_ filePaths: [String], in repository: URL) throws {}
        func discardAllChanges(in repository: URL) throws {}
        func commit(message: String, in repository: URL) throws -> String { "" }
        func push(in repository: URL) throws -> String { "" }
        func listRemotes(in repository: URL) -> [GitRemoteSummary] { [] }
        func addRemote(name: String, url: String, in repository: URL) throws {}
        func removeRemote(name: String, in repository: URL) throws {}
        func fetch(in repository: URL) throws {}
        func pull(in repository: URL) throws {}
        func pull(in repository: URL, strategy: GitRemoteOperation.PullStrategy) throws {}
        func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus {
            GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
        }
        func webLink(for url: String) -> URL? { nil }
        func isMerging(in repository: URL) -> Bool { false }
        func hasConflictOperation(in repository: URL) -> Bool { false }
        func conflictFiles(in repository: URL) -> [String] { [] }
        func mergeBranches(repository: URL, sourceBranch: String, targetBranch: String) throws -> String { "" }
        func mergeFileContent(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String { "" }
        func mergeFileDiff(path: String, in repository: URL) throws -> String { "" }
        func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws {}
        func continueMerge(in repository: URL) throws -> String { "" }
        func abortMerge(in repository: URL) throws -> String { "" }
        func finalizeMergeIfNeeded(in repository: URL) throws -> String? { nil }

        // MARK: - GitBackendRegistryProviding

        var availableBackends: [GitBackendDescriptor] { [] }
        func registerBackend(_ backend: any GitBackendProviding) throws {}
        func unregisterBackend(id: String) {}
    }

    // MARK: - Helpers

    private func makeChanges(count: Int) -> [GitFileChange] {
        (0..<count).map { index in
            GitFileChange(
                path: "files/file-\(index).txt",
                status: index.isMultiple(of: 3) ? .added : .modified,
                addedLines: index,
                deletedLines: 1
            )
        }
    }

    private func repoURL(_ name: String) -> URL {
        URL(fileURLWithPath: "/tmp/\(name)")
    }

    /// 轮询等待条件成立（分页任务在 MainActor 上异步完成）。
    private func waitUntil(
        timeout: TimeInterval = 5,
        _ condition: () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            await Task.yield()
        }
        XCTFail("waitUntil timed out", file: file, line: line)
    }

    // MARK: - Tests

    /// 首屏：reset 后能取到总数与第一页，且可经 `change(at:)` 按索引读取。
    func testLoadsCountAndFirstPage() async {
        let store = CommitFilePageStore()
        let mock = MockGitProviding()
        mock.changes = makeChanges(count: 25)

        store.reset(commitHash: "c1", repositoryURL: repoURL("a"), git: mock)

        await waitUntil { store.totalCount == 25 }
        await waitUntil { store.pages[0] != nil }

        XCTAssertEqual(store.totalCount, 25)
        XCTAssertEqual(store.pages[0]?.count, 25)
        XCTAssertEqual(store.change(at: 0)?.path, "files/file-0.txt")
        XCTAssertEqual(store.change(at: 24)?.path, "files/file-24.txt")
        XCTAssertNil(store.change(at: 25), "越界索引应返回 nil")
    }

    /// 并发去重：同一页在途时重复请求只触发一次后端加载。
    func testDeduplicatesConcurrentPageRequests() async {
        let store = CommitFilePageStore()
        let mock = MockGitProviding()
        mock.changes = makeChanges(count: 500)
        store.reset(commitHash: "c1", repositoryURL: repoURL("a"), git: mock)

        await waitUntil { store.totalCount == 500 }
        await waitUntil { store.pages[0] != nil }

        // 第 1 页尚未加载；同步连发两次请求，第二次应被 loadingPages 去重。
        store.requestPage(at: 1)
        store.requestPage(at: 1)
        await waitUntil { store.pages[1] != nil }

        XCTAssertEqual(mock.pageLoadCounts[1] ?? 0, 1, "同一页在途时应只加载一次")
        XCTAssertEqual(store.pages[1]?.count, 100)
    }

    /// 失败重试：某页首次失败后记录错误，retry 成功后清空错误并可读。
    func testRetriesFailedPage() async {
        let store = CommitFilePageStore()
        let mock = MockGitProviding()
        mock.changes = makeChanges(count: 500)
        mock.failCounts = [0: 1] // 第 0 页首次失败
        store.reset(commitHash: "c1", repositoryURL: repoURL("a"), git: mock)

        await waitUntil { store.pageErrors[0] != nil }
        XCTAssertNil(store.pages[0])
        XCTAssertEqual(store.firstFailedPageIndex, 0)

        store.retry(pageIndex: 0)
        await waitUntil { store.pages[0] != nil }

        XCTAssertNil(store.pageErrors[0])
        XCTAssertEqual(store.pages[0]?.count, 100)
        XCTAssertEqual(store.change(at: 0)?.path, "files/file-0.txt")
    }

    /// LRU 淘汰：常驻页数不超过配置上限，且被淘汰页可重新加载。
    func testEvictsLeastRecentlyUsedPages() async {
        let store = CommitFilePageStore()
        let mock = MockGitProviding()
        mock.changes = makeChanges(count: 2_000) // 20 页
        store.reset(commitHash: "c1", repositoryURL: repoURL("a"), git: mock)

        await waitUntil { store.totalCount == 2_000 }
        await waitUntil { store.pages[0] != nil }

        // 依序请求 10 页；等全部页加载完成并完成 LRU 裁剪后再断言。
        for page in 1..<10 {
            store.requestPage(at: page)
        }
        await waitUntil { store.loadingPages.isEmpty }

        XCTAssertLessThanOrEqual(
            store.pages.count,
            CommitFilePageStore.maxResidentPages,
            "常驻页数必须受 LRU 上限约束"
        )
        XCTAssertLessThanOrEqual(
            store.loadedChangeCount,
            CommitFilePageStore.pageSize * CommitFilePageStore.maxResidentPages
        )

        // 早期页已被淘汰：change(at:) 返回 nil，重新请求后可再加载。
        if store.pages[0] == nil {
            store.requestPage(at: 0)
            await waitUntil { store.pages[0] != nil }
            XCTAssertEqual(store.change(at: 0)?.path, "files/file-0.txt")
        }
    }

    /// commit 切换失效：reset 到新 commit 后清空旧页并加载新数据。
    func testResetInvalidatesPreviousCommitPages() async {
        let store = CommitFilePageStore()
        let mockA = MockGitProviding()
        mockA.changes = makeChanges(count: 250)
        store.reset(commitHash: "aaa", repositoryURL: repoURL("a"), git: mockA)
        await waitUntil { store.totalCount == 250 }
        await waitUntil { store.pages[0] != nil }
        XCTAssertEqual(store.change(at: 0)?.path, "files/file-0.txt")

        let mockB = MockGitProviding()
        mockB.changes = makeChanges(count: 30)
        store.reset(commitHash: "bbb", repositoryURL: repoURL("a"), git: mockB)
        await waitUntil { store.totalCount == 30 }
        await waitUntil { store.pages[0] != nil }

        XCTAssertEqual(store.totalCount, 30, "切换后应反映新 commit 的总数")
        XCTAssertEqual(store.change(at: 0)?.path, "files/file-0.txt")
        // 旧 commit 的页数据不得残留。
        XCTAssertTrue(store.pages.values.allSatisfy { $0.count <= 30 })
    }

    /// 性能/有界性：10,000+ 文件时，常驻内存受页缓存约束而非文件总数。
    func testMemoryStaysBoundedWithTenThousandFiles() async {
        let store = CommitFilePageStore()
        let mock = MockGitProviding()
        mock.changes = makeChanges(count: 10_000) // 100 页
        store.reset(commitHash: "c1", repositoryURL: repoURL("a"), git: mock)

        await waitUntil { store.totalCount == 10_000 }
        await waitUntil { store.pages[0] != nil }
        XCTAssertEqual(store.totalCount, 10_000)

        // 跨整个范围请求分散的多页（模拟跳转 / 快速滚动）；等全部完成后
        // 常驻页仍受页缓存约束。
        for page in [1, 5, 20, 60, 99] {
            store.requestPage(at: page)
        }
        await waitUntil { store.loadingPages.isEmpty }

        XCTAssertLessThanOrEqual(
            store.pages.count,
            CommitFilePageStore.maxResidentPages,
            "即使 commit 有 10,000+ 文件，常驻页数也必须受页缓存约束"
        )
        XCTAssertLessThanOrEqual(
            store.loadedChangeCount,
            CommitFilePageStore.pageSize * CommitFilePageStore.maxResidentPages,
            "常驻变更条数受页缓存约束，而非文件总数"
        )
        XCTAssertEqual(mock.countCalls, 1, "总数只需统计一次")
    }
}
