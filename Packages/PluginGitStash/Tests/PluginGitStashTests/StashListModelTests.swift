import Foundation
import KitGit
import Testing

@testable import PluginGitStash

// MARK: - Test Doubles

/// stash 面板能力的可配置替身：记录调用、注入结果与失败。
final class StubStashGit: StashGitCapability, @unchecked Sendable {
    var stashes: [GitStashEntry] = []
    var hasChanges = true
    /// 非 nil 时所有写操作抛出该错误。
    var failure: Error?
    /// 每个写操作被调用的次数，用于断言三路分发。
    private(set) var applyCallCount = 0
    private(set) var popCallCount = 0
    private(set) var dropCallCount = 0
    private(set) var saveMessages: [String?] = []
    private(set) var listCallCount = 0

    func listStashes(in repository: URL) -> [GitStashEntry] {
        listCallCount += 1
        return stashes
    }

    func hasChangesToStash(in repository: URL) -> Bool { hasChanges }

    func saveStash(message: String?, in repository: URL) throws {
        saveMessages.append(message)
        if let failure { throw failure }
    }

    func applyStash(_ entry: GitStashEntry, in repository: URL) throws {
        applyCallCount += 1
        if let failure { throw failure }
    }

    func popStash(_ entry: GitStashEntry, in repository: URL) throws {
        popCallCount += 1
        if let failure { throw failure }
    }

    func dropStash(_ entry: GitStashEntry, in repository: URL) throws {
        dropCallCount += 1
        if let failure { throw failure }
    }
}

/// 用于断言的简单错误。
private struct StashTestError: LocalizedError, Equatable {
    var errorDescription: String? { "boom" }
}

/// 等待后台任务完成。
///
/// Swift Testing 默认并行执行，固定 sleep 在负载高时可能不够，
/// 因此轮询条件直到满足或超时，避免脆弱的时序假设。
@MainActor
private func settle(
    timeout: TimeInterval = 5,
    until condition: @MainActor () -> Bool
) async {
    let deadline = ContinuousClock.now.advanced(by: .seconds(timeout))
    while ContinuousClock.now < deadline {
        if condition() { return }
        await Task.yield()
        try? await Task.sleep(nanoseconds: 2_000_000)
    }
}

// MARK: - Tests

@Suite("StashListModel")
@MainActor
struct StashListModelTests {

    private func makeModel(
        git: StubStashGit = StubStashGit(),
        repositoryURL: URL? = URL(fileURLWithPath: "/tmp/repo"),
        onStashesChanged: @escaping () -> Void = {},
        strings: StashListModel.StashPanelStrings = .init(
            noChangesToStash: "no-changes",
            stashSaved: "saved"
        )
    ) -> (StashListModel, StubStashGit) {
        let model = StashListModel(
            git: git,
            repositoryURL: { repositoryURL },
            onStashesChanged: onStashesChanged,
            strings: strings
        )
        return (model, git)
    }

    // MARK: 加载

    @Test("初始状态为加载中")
    func initialState() {
        let (model, _) = makeModel()
        #expect(model.isLoading)
        #expect(model.stashes.isEmpty)
        #expect(model.isPerformingAction == false)
        #expect(model.message == nil)
    }

    @Test("加载成功后结束加载态并填充列表")
    func loadPopulatesStashes() async {
        let git = StubStashGit()
        git.stashes = [GitStashEntry(index: 0, message: "wip"), GitStashEntry(index: 1, message: "")]
        let (model, _) = makeModel(git: git)

        model.load()
        await settle { model.stashes.count == 2 }

        #expect(model.isLoading == false)
        #expect(model.stashes == git.stashes)
    }

    @Test("无项目时清空列表并结束加载态")
    func loadWithoutRepository() async {
        let (model, git) = makeModel(repositoryURL: nil)

        // 无项目时同步早退，不进入后台任务
        model.load()

        #expect(model.isLoading == false)
        #expect(model.stashes.isEmpty)
        #expect(git.listCallCount == 0)
    }

    @Test("重复加载会读取最新列表")
    func reloadRefreshesStashes() async {
        let git = StubStashGit()
        git.stashes = [
            GitStashEntry(index: 0, message: "first"),
            GitStashEntry(index: 1, message: "second")
        ]
        let (model, _) = makeModel(git: git)

        model.load()
        await settle { model.stashes.count == 2 }
        git.stashes = [GitStashEntry(index: 0, message: "new")]
        model.load()
        await settle { model.stashes.count == 1 }

        #expect(model.stashes == git.stashes)
    }

    // MARK: 保存

    @Test("无项目时保存直接返回且不进入忙碌态")
    func saveWithoutRepository() async {
        let (model, git) = makeModel(repositoryURL: nil)
        model.stashMessage = "note"

        // 无项目时同步早退，不进入后台任务
        model.save()

        #expect(model.isPerformingAction == false)
        #expect(git.saveMessages.isEmpty)
    }

    @Test("无改动时提示并不调用保存")
    func saveWithoutChanges() async {
        let git = StubStashGit()
        git.hasChanges = false
        let (model, _) = makeModel(git: git)
        model.stashMessage = "note"

        // 无改动时同步早退
        model.save()

        #expect(model.message == .failure("no-changes"))
        #expect(git.saveMessages.isEmpty)
        #expect(model.isPerformingAction == false)
    }

    @Test("保存成功后清空输入、提示成功并触发变更回调")
    func saveSucceeds() async {
        let git = StubStashGit()
        var changedCount = 0
        let (model, _) = makeModel(git: git, onStashesChanged: { changedCount += 1 })
        model.stashMessage = "  my stash  "

        model.save()
        await settle { model.message == .success("saved") }

        // 输入被 trim 后传给 Git
        #expect(git.saveMessages == ["my stash"])
        #expect(model.stashMessage == "")
        #expect(model.message == .success("saved"))
        #expect(model.isPerformingAction == false)
        #expect(changedCount == 1)
    }

    @Test("空白消息按 nil 传给 Git")
    func saveBlankMessageBecomesNil() async {
        let git = StubStashGit()
        let (model, _) = makeModel(git: git)
        model.stashMessage = "   \n  "

        model.save()
        await settle { !git.saveMessages.isEmpty }

        #expect(git.saveMessages == [String?.none])
    }

    @Test("保存失败时展示错误且退出忙碌态")
    func saveFails() async {
        let git = StubStashGit()
        git.failure = StashTestError()
        let (model, _) = makeModel(git: git)

        model.save()
        await settle { model.message == .failure("boom") }

        #expect(model.message == .failure("boom"))
        #expect(model.isPerformingAction == false)
        #expect(model.stashMessage == "")
    }

    @Test("保存失败时不触发变更回调")
    func saveFailureSkipsCallback() async {
        let git = StubStashGit()
        git.failure = StashTestError()
        var changedCount = 0
        let (model, _) = makeModel(git: git, onStashesChanged: { changedCount += 1 })

        model.save()
        await settle { !git.saveMessages.isEmpty }

        #expect(changedCount == 0)
    }

    // MARK: 条目操作

    @Test("apply 触发 applyStash 并刷新列表")
    func performApply() async {
        let git = StubStashGit()
        var changedCount = 0
        let (model, _) = makeModel(git: git, onStashesChanged: { changedCount += 1 })
        let entry = GitStashEntry(index: 0, message: "wip")

        model.perform(.apply(entry))
        await settle { changedCount == 1 }

        #expect(git.applyCallCount == 1)
        #expect(git.popCallCount == 0)
        #expect(git.dropCallCount == 0)
        #expect(changedCount == 1)
        #expect(model.isPerformingAction == false)
    }

    @Test("pop 触发 popStash")
    func performPop() async {
        let git = StubStashGit()
        let (model, _) = makeModel(git: git)
        let entry = GitStashEntry(index: 1, message: "")

        model.perform(.pop(entry))
        await settle { git.popCallCount == 1 }

        #expect(git.popCallCount == 1)
        #expect(git.applyCallCount == 0)
        #expect(git.dropCallCount == 0)
    }

    @Test("drop 触发 dropStash")
    func performDrop() async {
        let git = StubStashGit()
        let (model, _) = makeModel(git: git)
        let entry = GitStashEntry(index: 2, message: "old")

        model.perform(.drop(entry))
        await settle { git.dropCallCount == 1 }

        #expect(git.dropCallCount == 1)
        #expect(git.applyCallCount == 0)
        #expect(git.popCallCount == 0)
    }

    @Test("无项目时条目操作直接返回")
    func performWithoutRepository() async {
        let (model, git) = makeModel(repositoryURL: nil)

        // 无项目时同步早退
        model.perform(.apply(GitStashEntry(index: 0, message: "")))

        #expect(git.applyCallCount == 0)
        #expect(model.isPerformingAction == false)
    }

    @Test("条目操作失败时展示错误且不触发变更回调")
    func performFails() async {
        let git = StubStashGit()
        git.failure = StashTestError()
        var changedCount = 0
        let (model, _) = makeModel(git: git, onStashesChanged: { changedCount += 1 })

        model.perform(.drop(GitStashEntry(index: 0, message: "")))
        await settle { model.message == .failure("boom") }

        #expect(model.message == .failure("boom"))
        #expect(model.isPerformingAction == false)
        #expect(changedCount == 0)
    }

    // MARK: 消息

    @Test("dismissMessage 清除消息")
    func dismissMessage() async {
        let git = StubStashGit()
        git.hasChanges = false
        let (model, _) = makeModel(git: git)

        model.save()
        await settle { model.message == .failure("no-changes") }
        #expect(model.message != nil)

        model.dismissMessage()

        #expect(model.message == nil)
    }

    @Test("新操作会清除旧消息")
    func newOperationClearsPreviousMessage() async {
        let git = StubStashGit()
        git.hasChanges = false
        let (model, _) = makeModel(git: git)
        model.save()
        await settle { model.message == .failure("no-changes") }
        #expect(model.message == .failure("no-changes"))

        git.hasChanges = true
        model.perform(.apply(GitStashEntry(index: 0, message: "")))

        #expect(model.message == nil)
        #expect(model.isPerformingAction)
    }

    // MARK: Action Equatable

    @Test("Action 支持相等比较")
    func actionEquatable() {
        let a = StashListModel.Action.apply(GitStashEntry(index: 1, message: "x"))
        let b = StashListModel.Action.apply(GitStashEntry(index: 1, message: "x"))
        let c = StashListModel.Action.drop(GitStashEntry(index: 1, message: "x"))

        #expect(a == b)
        #expect(a != c)
    }
}
