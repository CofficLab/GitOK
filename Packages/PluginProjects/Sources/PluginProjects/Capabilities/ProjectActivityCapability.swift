import Foundation
import KitGit
import ProviderGit

/// 读取仓库活跃度（最近一次提交时间）所需的最小能力。
///
/// 「最近更新」排序需要知道每个项目仓库的最近提交时间。该能力由
/// `GitProviding` 适配而来，视图只依赖本协议，不直接持有 Git Provider。
///
/// 协议要求 `Sendable`：读取提交历史是阻塞式 IO，会在后台任务中执行，
/// 因此能力对象需要能安全地跨并发域传递。
protocol ProjectActivityCapability: Sendable {
    /// 读取仓库中最近一次提交的时间；仓库没有提交或读取失败时返回 nil。
    func lastCommitDate(inRepository repositoryURL: URL) async -> Date?
}

/// 将 `GitProviding` 收窄成「读取最近提交时间」能力。
final class ProjectActivityCapabilityAdapter: ProjectActivityCapability {
    private let git: any GitProviding

    init(git: any GitProviding) {
        self.git = git
    }

    func lastCommitDate(inRepository repositoryURL: URL) async -> Date? {
        // 提交历史读取是阻塞式 IO，交给后台线程执行，避免卡住主线程。
        let git = self.git
        return await Task.detached(priority: .utility) {
            // 只取一条提交即可得到最近提交时间；limit 为 1 让 git 尽快返回。
            guard let commit = try? git.loadCommits(
                in: repositoryURL,
                limit: 1,
                offset: 0
            ).first else {
                return nil
            }
            return commit.date
        }.value
    }
}
