import Foundation
import KitGit
import Testing

@testable import PluginGitRemoteRepository

// MARK: - Test Doubles

/// 远程仓库能力的可配置替身：记录调用、注入结果与失败。
final class StubRemoteGit: RemoteRepositoryGitCapability, @unchecked Sendable {
    var remotes: [GitRemoteSummary] = []
    /// 非 nil 时所有写操作抛出该错误。
    var failure: Error?
    private(set) var listCallCount = 0
    private(set) var added: [(name: String, url: String)] = []
    private(set) var removedNames: [String] = []

    func listRemotes(in repository: URL) -> [GitRemoteSummary] {
        listCallCount += 1
        return remotes
    }

    func addRemote(name: String, url: String, in repository: URL) throws {
        added.append((name, url))
        if let failure { throw failure }
    }

    func removeRemote(name: String, in repository: URL) throws {
        removedNames.append(name)
        if let failure { throw failure }
    }
}

/// 用于断言的简单错误。
private struct RemoteTestError: LocalizedError, Equatable {
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

@Suite("RemoteRepositoryModel")
@MainActor
struct RemoteRepositoryModelTests {

    private func makeModel(
        git: StubRemoteGit = StubRemoteGit(),
        repositoryURL: URL? = URL(fileURLWithPath: "/tmp/repo")
    ) -> (RemoteRepositoryModel, StubRemoteGit) {
        let model = RemoteRepositoryModel(git: git, repositoryURL: { repositoryURL })
        return (model, git)
    }

    // MARK: 加载

    @Test("初始状态为加载中且列表为空")
    func initialState() {
        let (model, _) = makeModel()

        #expect(model.isLoading)
        #expect(model.remotes.isEmpty)
        #expect(model.errorMessage == nil)
        #expect(model.isPerformingAction == false)
    }

    @Test("加载成功后结束加载态并填充列表")
    func loadPopulatesRemotes() async {
        let git = StubRemoteGit()
        git.remotes = [
            GitRemoteSummary(name: "origin", url: "https://example.com/a.git"),
            GitRemoteSummary(name: "upstream", url: "https://example.com/b.git")
        ]
        let (model, _) = makeModel(git: git)

        model.load()
        await settle { model.remotes.count == 2 }

        #expect(model.isLoading == false)
        #expect(model.remotes == git.remotes)
    }

    @Test("无项目时清空列表并结束加载态且不读取")
    func loadWithoutRepository() async {
        let (model, git) = makeModel(repositoryURL: nil)

        // 无项目时同步早退
        model.load()

        #expect(model.isLoading == false)
        #expect(model.remotes.isEmpty)
        #expect(git.listCallCount == 0)
    }

    @Test("重复加载会读取最新列表")
    func reloadRefreshesRemotes() async {
        let git = StubRemoteGit()
        git.remotes = [
            GitRemoteSummary(name: "origin", url: "https://example.com/a.git"),
            GitRemoteSummary(name: "upstream", url: "https://example.com/b.git")
        ]
        let (model, _) = makeModel(git: git)

        model.load()
        await settle { model.remotes.count == 2 }

        git.remotes = [GitRemoteSummary(name: "only", url: "https://example.com/c.git")]
        model.load()
        await settle { model.remotes.count == 1 }

        #expect(model.remotes == git.remotes)
    }

    // MARK: 添加

    @Test("无项目时添加直接返回")
    func addWithoutRepository() async {
        let (model, git) = makeModel(repositoryURL: nil)

        model.addRemote(name: "origin", url: "https://example.com/a.git")

        #expect(git.added.isEmpty)
        #expect(model.isPerformingAction == false)
    }

    @Test("添加成功后刷新列表并清除错误")
    func addSucceeds() async {
        let git = StubRemoteGit()
        let (model, _) = makeModel(git: git)

        model.addRemote(name: "origin", url: "https://example.com/a.git")
        // 操作完成后列表会被刷新；先让替身返回新列表再等待写回
        git.remotes = [GitRemoteSummary(name: "origin", url: "https://example.com/a.git")]
        await settle { model.remotes.count == 1 }

        #expect(git.added.count == 1)
        #expect(git.added[0].name == "origin")
        #expect(git.added[0].url == "https://example.com/a.git")
        #expect(model.errorMessage == nil)
        #expect(model.isPerformingAction == false)
    }

    @Test("添加失败时展示错误并退出忙碌态")
    func addFails() async {
        let git = StubRemoteGit()
        git.failure = RemoteTestError()
        let (model, _) = makeModel(git: git)

        model.addRemote(name: "origin", url: "https://example.com/a.git")
        await settle { model.errorMessage == "boom" }

        #expect(model.errorMessage == "boom")
        #expect(model.isPerformingAction == false)
    }

    @Test("添加失败时保留原列表不刷新")
    func addFailureKeepsList() async {
        let git = StubRemoteGit()
        git.failure = RemoteTestError()
        let (model, _) = makeModel(git: git)

        model.addRemote(name: "origin", url: "https://example.com/a.git")
        await settle { model.errorMessage == "boom" }

        // 失败路径不重新读取列表
        #expect(git.listCallCount == 0)
        #expect(model.remotes.isEmpty)
    }

    // MARK: 删除

    @Test("无项目时删除直接返回")
    func deleteWithoutRepository() async {
        let (model, git) = makeModel(repositoryURL: nil)

        model.deleteRemote(GitRemoteSummary(name: "origin", url: "https://example.com/a.git"))

        #expect(git.removedNames.isEmpty)
        #expect(model.isPerformingAction == false)
    }

    @Test("删除成功后刷新列表并清除错误")
    func deleteSucceeds() async {
        let git = StubRemoteGit()
        let (model, _) = makeModel(git: git)

        model.deleteRemote(GitRemoteSummary(name: "origin", url: "https://example.com/a.git"))
        await settle { !git.removedNames.isEmpty && model.isPerformingAction == false }

        #expect(git.removedNames == ["origin"])
        #expect(model.errorMessage == nil)
        #expect(model.isPerformingAction == false)
    }

    @Test("删除失败时展示错误")
    func deleteFails() async {
        let git = StubRemoteGit()
        git.failure = RemoteTestError()
        let (model, _) = makeModel(git: git)

        model.deleteRemote(GitRemoteSummary(name: "origin", url: "https://example.com/a.git"))
        await settle { model.errorMessage == "boom" }

        #expect(git.removedNames == ["origin"])
        #expect(model.errorMessage == "boom")
        #expect(model.isPerformingAction == false)
    }

    @Test("删除失败时保留原列表不刷新")
    func deleteFailureKeepsList() async {
        let git = StubRemoteGit()
        git.failure = RemoteTestError()
        let (model, _) = makeModel(git: git)

        model.deleteRemote(GitRemoteSummary(name: "origin", url: "https://example.com/a.git"))
        await settle { model.errorMessage == "boom" }

        #expect(git.listCallCount == 0)
    }

    // MARK: 错误

    @Test("dismissError 清除错误提示")
    func dismissError() async {
        let git = StubRemoteGit()
        git.failure = RemoteTestError()
        let (model, _) = makeModel(git: git)

        model.addRemote(name: "origin", url: "https://example.com/a.git")
        await settle { model.errorMessage == "boom" }

        model.dismissError()

        #expect(model.errorMessage == nil)
    }

    @Test("新操作会清除旧错误")
    func newOperationClearsPreviousError() async {
        let git = StubRemoteGit()
        git.failure = RemoteTestError()
        let (model, _) = makeModel(git: git)
        model.addRemote(name: "origin", url: "https://example.com/a.git")
        await settle { model.errorMessage == "boom" }

        git.failure = nil
        model.deleteRemote(GitRemoteSummary(name: "origin", url: "https://example.com/a.git"))

        #expect(model.errorMessage == nil)
        #expect(model.isPerformingAction)
    }
}
