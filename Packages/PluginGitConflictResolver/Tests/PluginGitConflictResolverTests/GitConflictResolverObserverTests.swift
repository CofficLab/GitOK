import Foundation
import KitGit
import ProviderGitRepositoryWatch
import ProviderProjects
import Testing
@testable import PluginGitConflictResolver

/// `GitConflictResolverObserver` 的行为测试。
///
/// observer 把「仓库/项目事件」翻译成「读取一次 Git 快照并更新 ViewModel」，
/// 内部用 generation 计数丢弃过期结果、用 pending 标记合并并发重载。
/// 这些是整个插件里最容易出现竞态的部分，因此全部在这里覆盖。
@MainActor
@Suite("GitConflictResolverObserver")
struct GitConflictResolverObserverTests {

    // MARK: - Helpers

    /// 构造一个 observer 及其依赖，并返回测试句柄。
    private func makeObserver(
        projectURL: URL?,
        git: TestGitProviding,
        supportsRepositoryObservers: Bool = true
    ) -> (
        observer: GitConflictResolverObserver,
        viewModel: GitConflictResolverViewModel,
        capability: TestConflictResolverCapability
    ) {
        let capability = TestConflictResolverCapability()
        capability.currentProject = projectURL.map { Project(url: $0) }
        capability.supportsRepositoryObservers = supportsRepositoryObservers
        let viewModel = GitConflictResolverViewModel()
        let observer = GitConflictResolverObserver(
            capability: capability,
            git: git,
            viewModel: viewModel
        )
        return (observer, viewModel, capability)
    }

    /// 轮询等待条件成立：快照读取跑在 detached task 上，完成时机不由测试控制。
    @discardableResult
    private func waitUntil(
        timeout: TimeInterval = 5,
        _ condition: () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            await Task.yield()
        }
        return condition()
    }

    // MARK: - 初始加载

    @Test("构造时立即读取一次快照并弹出弹层")
    func loadsSnapshotOnInit() async {
        let url = URL(fileURLWithPath: "/tmp/obs-init")
        let git = TestGitProviding()
        git.conflictFilesStub = ["README.md"]
        git.isMergingStub = true

        let (observer, viewModel, _) = makeObserver(projectURL: url, git: git)
        defer { observer.cancel() }

        let loaded = await waitUntil { viewModel.hasLoadedSnapshot }
        #expect(loaded, "初始快照未生效")
        #expect(viewModel.conflictedFiles == ["README.md"])
        #expect(viewModel.isOperationInProgress)
        #expect(viewModel.isPresented, "检测到进行中的操作应自动弹出弹层")
    }

    @Test("没有当前项目时不读取仓库并清空状态")
    func noProjectSkipsSnapshot() async {
        let git = TestGitProviding()
        git.conflictFilesStub = ["README.md"]
        git.isMergingStub = true

        let (observer, viewModel, _) = makeObserver(projectURL: nil, git: git)
        defer { observer.cancel() }

        await waitUntil { viewModel.hasLoadedSnapshot }
        #expect(git.conflictFileReadCount == 0, "没有项目时不应读取仓库")
        #expect(viewModel.currentProjectURL == nil)
        #expect(viewModel.conflictedFiles.isEmpty)
        #expect(!viewModel.isOperationInProgress)
        #expect(!viewModel.isPresented)
    }

    @Test("cherry-pick 进行中同样视为操作进行中")
    func cherryPickingCountsAsInProgress() async {
        let url = URL(fileURLWithPath: "/tmp/obs-cherry")
        let git = TestGitProviding()
        git.conflictFilesStub = ["App.swift"]
        // isMerging 为 false，但 cherry-pick 正在进行。
        git.isMergingStub = false
        git.cherryPickStatusStub = GitCherryPickStatus(isCherryPicking: true, commitHash: "abc123")

        let (observer, viewModel, _) = makeObserver(projectURL: url, git: git)
        defer { observer.cancel() }

        let loaded = await waitUntil { viewModel.hasLoadedSnapshot }
        #expect(loaded)
        #expect(viewModel.isCherryPicking)
        #expect(viewModel.isOperationInProgress, "cherry-pick 进行中也应保持弹层")
        #expect(viewModel.isPresented)
    }

    // MARK: - 事件触发

    @Test("工作区变化事件会触发重新读取")
    func workingTreeEventTriggersReload() async {
        let url = URL(fileURLWithPath: "/tmp/obs-worktree")
        let git = TestGitProviding()
        git.conflictFilesStub = []
        git.isMergingStub = false

        let (observer, viewModel, capability) = makeObserver(projectURL: url, git: git)
        defer { observer.cancel() }

        let initial = await waitUntil { viewModel.hasLoadedSnapshot }
        #expect(initial)
        let readsAfterInit = git.conflictFileReadCount

        git.conflictFilesStub = ["new.txt"]
        git.isMergingStub = true
        capability.sendRepositoryEvent(.workingTreeChanged)

        let reloaded = await waitUntil { viewModel.conflictedFiles == ["new.txt"] }
        #expect(reloaded, "工作区变化后未刷新冲突列表")
        #expect(git.conflictFileReadCount > readsAfterInit)
        #expect(viewModel.isPresented)
    }

    @Test("stash 与 refs 变化不触发重新读取")
    func stashAndRefsEventsAreIgnored() async {
        let url = URL(fileURLWithPath: "/tmp/obs-stash")
        let git = TestGitProviding()
        git.conflictFilesStub = []
        git.isMergingStub = false

        let (observer, viewModel, capability) = makeObserver(projectURL: url, git: git)
        defer { observer.cancel() }

        let initial = await waitUntil { viewModel.hasLoadedSnapshot }
        #expect(initial)
        let readsAfterInit = git.conflictFileReadCount

        capability.sendRepositoryEvent(.stashChanged)
        capability.sendRepositoryEvent(.refsChanged)
        // 给可能误触发的异步任务机会跑完再断言。
        await Task.yield()

        #expect(git.conflictFileReadCount == readsAfterInit, "stash/refs 变化不应重新读取仓库")
    }

    @Test("项目选择变化会切到新仓库并清空旧状态")
    func projectChangeReloadsNewRepository() async {
        let first = URL(fileURLWithPath: "/tmp/obs-first")
        let second = URL(fileURLWithPath: "/tmp/obs-second")
        let git = TestGitProviding()
        git.conflictFilesStub = ["first.txt"]
        git.isMergingStub = true

        let (observer, viewModel, capability) = makeObserver(projectURL: first, git: git)
        defer { observer.cancel() }

        let initial = await waitUntil { viewModel.conflictedFiles == ["first.txt"] }
        #expect(initial)
        #expect(viewModel.isPresented)

        git.conflictFilesStub = ["second.txt"]
        capability.currentProject = Project(url: second)
        capability.sendProjectEvent(.selectionChanged(projectID: UUID()))

        let switched = await waitUntil { viewModel.currentProjectURL == second }
        #expect(switched, "切换项目后未生效")
        let settled = await waitUntil { viewModel.conflictedFiles == ["second.txt"] }
        #expect(settled, "切换项目后未读取新仓库的冲突列表")
        #expect(viewModel.isPresented, "新项目存在冲突时应重新弹出")
    }

    // MARK: - 竞态

    @Test("读取进行中收到多个事件只合并为一次后续读取")
    func concurrentReloadsAreCoalesced() async {
        let url = URL(fileURLWithPath: "/tmp/obs-coalesce")
        let git = TestGitProviding()
        git.conflictFilesStub = ["a.txt"]
        git.isMergingStub = true

        let (observer, viewModel, capability) = makeObserver(projectURL: url, git: git)
        defer { observer.cancel() }

        // 首次读取阻塞在 conflictFiles 里，后续事件只能走 pending 分支。
        git.blocksConflictFileRead = true
        capability.sendRepositoryEvent(.workingTreeChanged)

        let blocked = await waitUntil { git.isConflictFileReadBlocked }
        #expect(blocked, "快照读取未进入阻塞状态")

        // 在阻塞期间连续投递事件。
        git.conflictFilesStub = ["b.txt"]
        for _ in 0..<5 {
            capability.sendRepositoryEvent(.workingTreeChanged)
            await Task.yield()
        }

        git.releaseConflictFiles()

        let settled = await waitUntil { viewModel.conflictedFiles == ["b.txt"] }
        #expect(settled, "合并后的后续读取未生效")
        // 初始 1 次 + 阻塞中的 1 次 + 合并后的 1 次。
        #expect(git.conflictFileReadCount <= 3, "并发事件被重复读取：\(git.conflictFileReadCount)")

        // 等到系统静止后再断言：读取计数一旦超过合并上限就说明 pending 标记
        // 失效了，后续读取会自我触发成死循环。只看最终计数会漏掉这种回归，
        // 因为断言可能在多出来的读取发生前就已经通过。
        let readsAtSettle = git.conflictFileReadCount
        for _ in 0..<20 { await Task.yield() }
        #expect(git.conflictFileReadCount == readsAtSettle, "读取已收敛，计数仍在增长：\(git.conflictFileReadCount)")
    }

    @Test("过期快照不会发布到 ViewModel")
    func staleSnapshotIsDiscarded() async {
        let url = URL(fileURLWithPath: "/tmp/obs-stale")
        let git = TestGitProviding()
        git.conflictFilesStub = ["old.txt"]
        git.isMergingStub = true

        let (observer, viewModel, capability) = makeObserver(projectURL: url, git: git)
        defer { observer.cancel() }

        // 记录冲突列表的每一次发布值。只断言最终值是不够的：过期快照若被
        // 丢弃，最终值与正确实现完全一致，测试就会假通过。中间态才能
        // 区分「丢弃旧快照」和「先写旧值再写新值」。
        var publishedFiles: [[String]] = []
        let cancellable = viewModel.$conflictedFiles.sink { publishedFiles.append($0) }
        defer { cancellable.cancel() }

        // 第一次读取阻塞，等待它启动。
        git.blocksConflictFileRead = true
        capability.sendRepositoryEvent(.workingTreeChanged)
        let blocked = await waitUntil { git.isConflictFileReadBlocked }
        #expect(blocked)

        // 排队一次新的读取请求；它会提升 generation。
        git.conflictFilesStub = ["new.txt"]
        capability.sendRepositoryEvent(.workingTreeChanged)
        await Task.yield()

        git.releaseConflictFiles()

        let settled = await waitUntil { viewModel.conflictedFiles == ["new.txt"] }
        #expect(settled, "最新一次读取未生效")
        #expect(
            !publishedFiles.contains(["old.txt"]),
            "过期的 old.txt 快照被发布到了 ViewModel，实际序列：\(publishedFiles)"
        )
    }

    // MARK: - requestPresentation

    @Test("请求展示时会先刷新状态再打开弹层")
    func requestPresentationRefreshesThenPresents() async {
        let url = URL(fileURLWithPath: "/tmp/obs-request")
        let git = TestGitProviding()
        git.conflictFilesStub = []
        git.isMergingStub = false

        let (observer, viewModel, _) = makeObserver(projectURL: url, git: git)
        defer { observer.cancel() }

        let initial = await waitUntil { viewModel.hasLoadedSnapshot }
        #expect(initial)
        #expect(!viewModel.isPresented)

        // 请求展示的同时，仓库里出现了冲突。
        git.conflictFilesStub = ["late.txt"]
        git.isMergingStub = true
        observer.requestPresentation()

        let presented = await waitUntil { viewModel.isPresented }
        #expect(presented, "requestPresentation 未能打开弹层")
        #expect(viewModel.conflictedFiles == ["late.txt"])
    }

    @Test("请求展示时若仓库没有进行中的操作则不弹出")
    func requestPresentationDoesNotOpenWithoutOperation() async {
        let url = URL(fileURLWithPath: "/tmp/obs-request-none")
        let git = TestGitProviding()
        git.conflictFilesStub = ["ignored.txt"]
        git.isMergingStub = false

        let (observer, viewModel, _) = makeObserver(projectURL: url, git: git)
        defer { observer.cancel() }

        let initial = await waitUntil { viewModel.hasLoadedSnapshot }
        #expect(initial)

        observer.requestPresentation()

        // 读取完成后再断言，确保 present 已经有机会执行。
        let readCount = git.conflictFileReadCount
        _ = await waitUntil { git.conflictFileReadCount > readCount }
        #expect(!viewModel.isPresented, "没有进行中的操作时不应弹出弹层")
    }

    // MARK: - 生命周期

    @Test("cancel 会取消在途任务并解除观察")
    func cancelStopsObservers() async {
        let url = URL(fileURLWithPath: "/tmp/obs-cancel")
        let git = TestGitProviding()
        git.conflictFilesStub = ["a.txt"]
        git.isMergingStub = true

        let (observer, viewModel, capability) = makeObserver(projectURL: url, git: git)
        let initial = await waitUntil { viewModel.conflictedFiles == ["a.txt"] }
        #expect(initial)

        observer.cancel()

        #expect(capability.projectHandles.allSatisfy { $0.isCancelled }, "项目观察句柄未释放")
        #expect(capability.repositoryHandles.allSatisfy { $0.isCancelled }, "仓库观察句柄未释放")

        let readsAfterCancel = git.conflictFileReadCount
        capability.sendRepositoryEvent(.workingTreeChanged)
        capability.sendProjectEvent(.dataChanged)
        await Task.yield()

        #expect(git.conflictFileReadCount == readsAfterCancel, "cancel 后不应再读取仓库")
    }

    @Test("未注册仓库监听时仍可工作")
    func worksWithoutRepositoryObserver() async {
        let url = URL(fileURLWithPath: "/tmp/obs-no-repo-watch")
        let git = TestGitProviding()
        git.conflictFilesStub = ["a.txt"]
        git.isMergingStub = true

        let (observer, viewModel, capability) = makeObserver(
            projectURL: url,
            git: git,
            supportsRepositoryObservers: false
        )
        defer { observer.cancel() }

        let loaded = await waitUntil { viewModel.conflictedFiles == ["a.txt"] }
        #expect(loaded, "没有仓库监听时仍应完成初始读取")
        #expect(capability.repositoryHandles.isEmpty)

        // 项目事件仍能触发刷新。
        git.conflictFilesStub = ["b.txt"]
        let readsBefore = git.conflictFileReadCount
        capability.sendProjectEvent(.dataChanged)
        let reloaded = await waitUntil { git.conflictFileReadCount > readsBefore }
        #expect(reloaded)
    }
}
