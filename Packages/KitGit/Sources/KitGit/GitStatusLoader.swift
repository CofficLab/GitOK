import Foundation

/// 仓库工作区状态（由 `git status --porcelain` 判定）。
public struct GitWorktreeStatus: Equatable, Sendable {
    /// 工作区是否干净（无任何未提交/未跟踪变更）。
    public let isClean: Bool
    /// 未提交变更的条数（porcelain 行数，不含 `##` 分支行）。
    public let changeCount: Int
    /// 当前分支名（如 `main`）；处于 detached HEAD 时为 `HEAD`，无仓库时为 nil。
    public let branch: String?

    public init(isClean: Bool, changeCount: Int, branch: String?) {
        self.isClean = isClean
        self.changeCount = changeCount
        self.branch = branch
    }
}

/// 通过 git CLI 读取仓库工作区状态。
public enum GitStatusLoader {
    /// 读取工作区状态。
    ///
    /// 使用 `git status --porcelain=v1 --branch --untracked-files=normal`：
    /// - 首行 `## <branch>...<upstream>` 提供分支名（含 detached HEAD 的 `## HEAD`）；
    /// - 其余非空行即未提交变更（含未跟踪文件），计数为 `changeCount`。
    public static func loadStatus(in repository: URL) throws -> GitWorktreeStatus {
        let output = try GitProcessRunner.run(
            ["status", "--porcelain=v1", "--branch", "--untracked-files=normal"],
            in: repository
        )
        var branch: String?
        var changeCount = 0
        for line in output.split(separator: "\n") {
            let s = String(line)
            if s.hasPrefix("## ") {
                branch = Self.parseBranch(s)
            } else if !s.isEmpty {
                changeCount += 1
            }
        }
        return GitWorktreeStatus(isClean: changeCount == 0, changeCount: changeCount, branch: branch)
    }

    /// 解析 `## <branch>...<upstream>` 或 `## HEAD (no branch)` 得到分支名。
    private static func parseBranch(_ line: String) -> String? {
        let rest = String(line.dropFirst(3))
        let branch = rest.split(separator: "...").first.map(String.init) ?? "HEAD"
        // `## HEAD (no branch)` / `## main...origin/main [ahead 1]` → 取首段。
        return branch.split(separator: " ").first.map(String.init) ?? branch
    }
}
