import Foundation
import KitGit

/// 依据上次保存的选择，把分支列表解析为源 / 目标分支。
///
/// 刷新完成后列表可能与打开弹层时不同（分支被删、当前分支被切换），因此
/// 解析优先级为：用户当前已选且仍存在 > 上次保存且仍存在 > 默认（源取
/// 非当前分支，目标取当前分支）。
enum MergeBranchSelectionResolver {
    static func resolve(
        branches: [GitBranchSummary],
        saved: MergeSelection?,
        keeping currentSource: GitBranchSummary? = nil,
        currentTarget: GitBranchSummary? = nil
    ) -> (source: GitBranchSummary?, target: GitBranchSummary?) {
        guard !branches.isEmpty else { return (nil, nil) }

        let savedSource = saved?.sourceBranchName.flatMap { name in
            branches.first { $0.name == name }
        }
        let savedTarget = saved?.targetBranchName.flatMap { name in
            branches.first { $0.name == name }
        }

        var source = existing(currentSource, in: branches)
            ?? savedSource
            ?? branches.first { !$0.isCurrent }
            ?? branches.first
        var target = existing(currentTarget, in: branches)
            ?? savedTarget
            ?? branches.first { $0.isCurrent }
            ?? branches.first

        if branches.count > 1, let targetName = target?.name, source?.name == targetName {
            source = branches.first { $0.name != targetName }
        }
        return (source, target)
    }

    private static func existing(
        _ branch: GitBranchSummary?,
        in branches: [GitBranchSummary]
    ) -> GitBranchSummary? {
        guard let branch else { return nil }
        return branches.first { $0.name == branch.name }
    }
}