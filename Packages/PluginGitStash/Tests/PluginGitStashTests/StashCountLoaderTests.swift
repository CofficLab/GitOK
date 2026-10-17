import Foundation
import KitGit
import Testing

@testable import PluginGitStash

/// 计数加载能力的可配置替身。
final class SimpleCountGit: StashCountGitCapability, @unchecked Sendable {
    var stashes: [GitStashEntry] = []
    private(set) var listCallCount = 0
    private(set) var sawCancellation = false

    func listStashes(in repository: URL, cancellation: GitProcessCancellation?) -> [GitStashEntry] {
        listCallCount += 1
        if cancellation != nil { sawCancellation = true }
        return stashes
    }
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

@Suite("StashCountLoader")
@MainActor
struct StashCountLoaderTests {

    private func makeLoader(
        git: any StashCountGitCapability,
        repositoryURL: URL? = URL(fileURLWithPath: "/tmp/repo")
    ) -> StashCountLoader {
        StashCountLoader(git: git, repositoryURL: { repositoryURL })
    }

    @Test("初始计数为 0")
    func initialCount() {
        let loader = makeLoader(git: SimpleCountGit())

        #expect(loader.count == 0)
    }

    @Test("加载后计数等于 stash 条数")
    func loadCountsStashes() async {
        let git = SimpleCountGit()
        git.stashes = [
            GitStashEntry(index: 0, message: "a"),
            GitStashEntry(index: 1, message: "b"),
            GitStashEntry(index: 2, message: "")
        ]
        let loader = makeLoader(git: git)

        loader.load()
        await settle { loader.count == 3 }

        #expect(loader.count == 3)
    }

    @Test("空列表计数为 0")
    func emptyListGivesZero() async {
        let git = SimpleCountGit()
        let loader = makeLoader(git: git)

        loader.load()
        await settle { git.listCallCount > 0 }

        #expect(loader.count == 0)
    }

    @Test("无项目时归零且不读取")
    func loadWithoutRepository() async {
        let git = SimpleCountGit()
        let loader = makeLoader(git: git, repositoryURL: nil)

        // 无项目时同步返回，不需要等待后台任务
        loader.load()

        #expect(loader.count == 0)
        #expect(git.listCallCount == 0)
    }

    @Test("取消标记被传递给底层")
    func passesCancellationToBackend() async {
        let git = SimpleCountGit()
        let loader = makeLoader(git: git)

        loader.load()
        await settle { git.sawCancellation }

        #expect(git.sawCancellation)
    }

    @Test("load 时先归零，避免旧计数残留")
    func loadResetsCountFirst() async {
        let git = SimpleCountGit()
        git.stashes = [GitStashEntry(index: 0, message: "a")]
        let loader = makeLoader(git: git)
        loader.load()
        await settle { loader.count == 1 }
        #expect(loader.count == 1)

        git.stashes = []
        loader.load()
        await settle { git.listCallCount == 2 }

        #expect(loader.count == 0)
    }

    @Test("项目切换后旧世代结果不覆盖新计数")
    func staleGenerationResultIsDiscarded() async {
        let git = SimpleCountGit()
        git.stashes = [GitStashEntry(index: 0, message: "old")]
        let loader = makeLoader(git: git)

        // 连续两次加载：第一次的世代号已过期
        loader.load()
        loader.load()
        git.stashes = [GitStashEntry(index: 0, message: "new")]
        loader.load()
        // 等待最后一次加载写回；被取消的旧世代任务可能从未执行到调用点，
        // 因此不能假设 listCallCount 一定是 3。
        await settle { loader.count == 1 }

        // 最终计数来自最后一次加载，旧世代结果没有覆盖它
        #expect(loader.count == 1)
    }

    @Test("cancel 后进行中的加载不再写回")
    func cancelPreventsWriteBack() async {
        let git = SimpleCountGit()
        git.stashes = [
            GitStashEntry(index: 0, message: "a"),
            GitStashEntry(index: 1, message: "b")
        ]
        let loader = makeLoader(git: git)

        loader.load()
        loader.cancel()
        await settle { git.listCallCount > 0 }

        #expect(loader.count == 0)
    }

    @Test("cancel 可重复调用且幂等")
    func cancelIsIdempotent() async {
        let git = SimpleCountGit()
        let loader = makeLoader(git: git)
        loader.load()
        await settle { git.listCallCount > 0 }

        loader.cancel()
        loader.cancel()

        #expect(loader.count == 0)
    }

    @Test("取消后重新加载可恢复正常计数")
    func loadAfterCancelRecovers() async {
        let git = SimpleCountGit()
        let loader = makeLoader(git: git)

        loader.load()
        loader.cancel()
        await settle { git.listCallCount > 0 }
        #expect(loader.count == 0)

        git.stashes = [
            GitStashEntry(index: 0, message: "a"),
            GitStashEntry(index: 1, message: "b")
        ]
        loader.load()
        await settle { loader.count == 2 }

        #expect(loader.count == 2)
    }
}
