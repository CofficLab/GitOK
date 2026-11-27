import Foundation
import KitGit
import ProviderGit

/// 合并弹层的本地分支读取器：优先走系统 git CLI，缺失或执行失败时回退后端。
///
/// 分支读取在 libgit2 后端里要排同一个仓库的串行执行队列，队列被工作区扫描、
/// 提交分页占住时会有秒级等待。CLI 是独立进程，不占用该队列，实测本地 ref
/// 读取在毫秒级；没有安装 git 的机器仍由 `GitProviding` 兜底，行为与不接
/// CLI 时完全一致。
struct MergeBranchReader: Sendable {
    typealias LocalBranchLoader = @Sendable (URL) throws -> [GitBranchSummary]

    let isCLIAvailable: @Sendable () -> Bool
    let loadWithCLI: LocalBranchLoader
    let loadWithFallback: LocalBranchLoader

    func loadLocalBranches(in repository: URL) throws -> [GitBranchSummary] {
        if isCLIAvailable() {
            if let branches = try? loadWithCLI(repository), !branches.isEmpty {
                return branches
            }
        }
        return try loadWithFallback(repository)
    }
}

extension MergeBranchReader {
    static func live(git: any GitProviding) -> MergeBranchReader {
        MergeBranchReader(
            isCLIAvailable: { GitProcessRunner.isAvailable },
            loadWithCLI: { repository in
                try loadLocalBranchesWithCLI(in: repository)
            },
            loadWithFallback: { repository in
                try git.listBranches(in: repository).filter { !$0.isRemote }
            }
        )
    }

    private static let cliTimeout: TimeInterval = 5

    /// `%(HEAD)` 对当前分支输出 `*`、其余输出空格，因此只需一个子进程。
    private static func loadLocalBranchesWithCLI(in repository: URL) throws -> [GitBranchSummary] {
        let output = try GitProcessRunner.run(
            ["for-each-ref", "refs/heads", "--format=%(HEAD)%(refname:short)"],
            in: repository,
            timeout: cliTimeout
        )
        return output.split(separator: "\n").compactMap { line in
            let isCurrent = line.hasPrefix("*")
            let name = (isCurrent ? line.dropFirst() : line)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return GitBranchSummary(name: name, isRemote: false, isCurrent: isCurrent)
        }
    }
}