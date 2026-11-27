import Foundation
import KitGit
import ProviderGit

/// 分支选择弹层的分支读取器：优先走系统 git CLI，缺失或执行失败时回退后端。
///
/// 分支读取在 libgit2 后端里要排同一个仓库的串行执行队列，队列被工作区扫描、
/// 提交分页占住时会有秒级等待。CLI 是独立进程，不占用该队列；没有安装 git
/// 的机器仍由 `GitProviding` 兜底，行为与不接 CLI 时完全一致。
struct BranchListReader: Sendable {
    typealias BranchLoader = @Sendable (URL) throws -> [GitBranchSummary]

    let isCLIAvailable: @Sendable () -> Bool
    let loadWithCLI: BranchLoader
    let loadWithFallback: BranchLoader

    func loadBranches(in repository: URL) throws -> [GitBranchSummary] {
        if isCLIAvailable() {
            if let branches = try? loadWithCLI(repository), !branches.isEmpty {
                return branches
            }
        }
        return try loadWithFallback(repository)
    }
}

extension BranchListReader {
    static func live(git: any GitProviding) -> BranchListReader {
        BranchListReader(
            isCLIAvailable: { GitProcessRunner.isAvailable },
            loadWithCLI: { repository in
                try loadBranchesWithCLI(in: repository)
            },
            loadWithFallback: { repository in
                try git.listBranches(in: repository)
            }
        )
    }

    private static let cliTimeout: TimeInterval = 5

    /// `%(HEAD)` 对当前分支输出 `*`、其余输出空格；用完整 refname 一次列出
    /// 本地与远程分支，既只需一个子进程，也能可靠区分两类引用。
    private static func loadBranchesWithCLI(in repository: URL) throws -> [GitBranchSummary] {
        let output = try GitProcessRunner.run(
            ["for-each-ref", "refs/heads", "refs/remotes", "--format=%(HEAD)%(refname)"],
            in: repository,
            timeout: cliTimeout
        )
        return output.split(separator: "\n").compactMap { line in
            let isCurrent = line.hasPrefix("*")
            let ref = (isCurrent ? line.dropFirst() : line)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if ref.hasPrefix("refs/heads/") {
                let name = ref.dropFirst("refs/heads/".count)
                guard !name.isEmpty else { return nil }
                return GitBranchSummary(name: String(name), isRemote: false, isCurrent: isCurrent)
            }
            if ref.hasPrefix("refs/remotes/") {
                let name = ref.dropFirst("refs/remotes/".count)
                guard !name.isEmpty, !name.hasSuffix("/HEAD") else { return nil }
                return GitBranchSummary(name: String(name), isRemote: true, isCurrent: false)
            }
            return nil
        }
    }
}