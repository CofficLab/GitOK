import Foundation
import KitGit
import Observation
import ProviderGit

/// 状态栏计数加载所需的最小 Git 能力边界。
///
/// 只声明「可取消地列出 stash」一个成员，避免计数逻辑依赖整个 `GitProviding`。
protocol StashCountGitCapability: Sendable {
    func listStashes(in repository: URL, cancellation: GitProcessCancellation?) -> [GitStashEntry]
}

/// 将 `any GitProviding` 收窄为计数加载所需的能力。
struct StashCountGitCapabilityAdapter: StashCountGitCapability {
    private let git: any GitProviding

    init(git: any GitProviding) {
        self.git = git
    }

    func listStashes(in repository: URL, cancellation: GitProcessCancellation?) -> [GitStashEntry] {
        git.listStashes(in: repository, cancellation: cancellation)
    }
}

/// 状态栏 tile 的 stash 计数加载器。
///
/// 承载「读列表 → 只取条数」以及**世代守卫**与**取消**语义：
/// 每次加载自增世代号并取消上一轮任务，回写时同时校验世代与取消标记，
/// 因此项目快速切换时旧请求的结果不会覆盖新项目的计数。
@MainActor
@Observable
final class StashCountLoader {
    /// 当前 stash 数量；无项目或加载中时为 0。
    private(set) var count = 0

    private let git: any StashCountGitCapability
    private let repositoryURL: () -> URL?

    /// 世代号；`&+=` 防止极端长期运行溢出。
    private var generation = 0
    private var task: Task<Void, Never>?
    private var cancellation: GitProcessCancellation?

    init(git: any StashCountGitCapability, repositoryURL: @escaping () -> URL?) {
        self.git = git
        self.repositoryURL = repositoryURL
    }

    /// 重新加载计数。
    ///
    /// 无选中项目时直接归零并取消进行中的加载。
    func load() {
        generation &+= 1
        let generation = self.generation
        cancel()

        guard let url = repositoryURL() else {
            count = 0
            return
        }

        count = 0
        let cancellation = GitProcessCancellation()
        self.cancellation = cancellation
        let git = self.git
        task = Task.detached(priority: .utility) {
            let loaded = git.listStashes(in: url, cancellation: cancellation)
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard
                    let self,
                    generation == self.generation,
                    !cancellation.isCancelled
                else { return }
                self.count = loaded.count
                self.task = nil
                self.cancellation = nil
            }
        }
    }

    /// 取消进行中的加载；结果不再写回。
    func cancel() {
        task?.cancel()
        task = nil
        cancellation?.cancel()
        cancellation = nil
    }
}
