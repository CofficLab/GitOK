import Foundation

/// 分支摘要（对齐旧版 KitGitCore.GitBranchSummary）。
public struct GitBranchSummary: Identifiable, Equatable, Hashable, Sendable {
    public let name: String
    public let isRemote: Bool
    public let isCurrent: Bool

    public init(name: String, isRemote: Bool, isCurrent: Bool) {
        self.name = name
        self.isRemote = isRemote
        self.isCurrent = isCurrent
    }

    public var id: String { name }
}

/// 分支操作：列表、新建、切换、删除（对齐旧版 GitRepositoryCLI 分支能力）。
public enum GitBranchOperation {
    /// 列出本地与远程分支。
    public static func listBranches(in repository: URL) throws -> [GitBranchSummary] {
        // 本地分支：`git for-each-ref refs/heads --format=%(refname:short)`，当前分支带 *。
        let localOut = try GitProcessRunner.run(
            ["for-each-ref", "refs/heads", "--format=%(refname:short)"],
            in: repository
        )
        var localNames = localOut
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        // 移除 * 前缀（for-each-ref 不带 *，branch --show-current 用于判断当前分支）。
        localNames.removeAll { $0 == "*" }
        let current = GitRefReader.currentBranch(in: repository)

        var result = localNames.map {
            GitBranchSummary(name: String($0), isRemote: false, isCurrent: $0 == current)
        }

        // 远程分支：`git for-each-ref refs/remotes --format=%(refname:short)`，排除 origin/HEAD。
        if let remoteOut = try? GitProcessRunner.run(
            ["for-each-ref", "refs/remotes", "--format=%(refname:short)"],
            in: repository
        ) {
            let remoteNames = remoteOut
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasSuffix("/HEAD") }
            result += remoteNames.map {
                GitBranchSummary(name: String($0), isRemote: true, isCurrent: false)
            }
        }
        return result
    }

    /// 新建分支。
    public static func createBranch(named name: String, in repository: URL) throws {
        _ = try GitProcessRunner.run(["branch", name], in: repository)
    }

    /// 切换分支。
    public static func checkoutBranch(named name: String, in repository: URL) throws {
        _ = try GitProcessRunner.run(["checkout", name], in: repository)
    }

    /// 删除本地分支（-d 保守删除，仅已合并分支）。
    public static func deleteBranch(named name: String, in repository: URL) throws {
        _ = try GitProcessRunner.run(["branch", "-d", name], in: repository)
    }
}
