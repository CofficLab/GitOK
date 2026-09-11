import Foundation

/// 仓库工作区状态（由 `git status --porcelain` 判定）。
public struct GitWorktreeStatus: Equatable, Sendable {
    /// 工作区是否干净（无任何未提交/未跟踪变更）。
    public let isClean: Bool
    /// 未提交变更的条数（展开未跟踪目录后的文件条数，不含分支行）。
    public let changeCount: Int
    /// 当前分支名（如 `main`）；处于 detached HEAD 时为 `HEAD`，无仓库时为 nil。
    public let branch: String?

    public init(isClean: Bool, changeCount: Int, branch: String?) {
        self.isClean = isClean
        self.changeCount = changeCount
        self.branch = branch
    }
}

/// 工作区变动文件条目（由 `git status --porcelain` 解析）。
public struct GitStatusEntry: Equatable, Sendable, Identifiable {
    /// 文件路径（相对仓库根）。
    public let path: String
    /// 暂存区状态（X 列）：M/A/D/R/C/?? 等；空格表示未暂存。
    public let stagedStatus: Character
    /// 工作区状态（Y 列）：M/A/D/R/C/?? 等；空格表示无工作区变更。
    public let worktreeStatus: Character
    /// 是否为未跟踪文件（??）。
    public var isUntracked: Bool { stagedStatus == "?" && worktreeStatus == "?" }
    /// 是否有暂存变更（X 列非空格非?）。
    public var isStaged: Bool { stagedStatus != " " && stagedStatus != "?" }
    /// 是否有工作区变更（Y 列非空格非?）。
    public var isWorktreeModified: Bool { worktreeStatus != " " && worktreeStatus != "?" }
    /// 唯一标识（用路径）。
    public var id: String { path }

    public init(path: String, stagedStatus: Character, worktreeStatus: Character) {
        self.path = path
        self.stagedStatus = stagedStatus
        self.worktreeStatus = worktreeStatus
    }
}

/// 通过 git CLI 读取仓库工作区状态。
public enum GitStatusLoader {
    /// `git status` 会递归检查未跟踪文件；单个异常目录不能无限期阻塞所有
    /// 工作区视图，因此状态读取设置独立的硬超时。
    public static let commandTimeout: TimeInterval = 15

    public enum Error: Swift.Error, Equatable, LocalizedError {
        case notARepository(URL)

        public var errorDescription: String? {
            switch self {
            case .notARepository(let url):
                String(format: LumiPluginLocalization.string(
                    "This directory is not a Git repository: %@",
                    bundle: .module
                ), url.lastPathComponent)
            }
        }
    }

    /// 读取工作区状态。
    ///
    /// 使用 `git status --porcelain=v1 --branch --untracked-files=all`：
    /// - 首行 `## <branch>...<upstream>` 提供分支名（含 detached HEAD 的 `## HEAD`）；
    /// - 其余非空行即未提交变更（含展开后的未跟踪目录文件），计数为 `changeCount`。
    public static func loadStatus(in repository: URL) throws -> GitWorktreeStatus {
        try validateRepository(repository)
        let output = try GitProcessRunner.run(
            ["status", "--porcelain=v1", "--branch", "--untracked-files=all"],
            in: repository,
            timeout: commandTimeout
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

    /// 读取工作区变动文件列表。
    ///
    /// 使用 `git status --porcelain=v1 --untracked-files=all`，解析每一行的
    /// XY 状态码和路径。未跟踪目录会展开为其中的文件；重命名/复制（R/C）只取目标路径。
    public static func loadEntries(in repository: URL) throws -> [GitStatusEntry] {
        try validateRepository(repository)
        let output = try GitProcessRunner.run(
            ["status", "--porcelain=v1", "--untracked-files=all"],
            in: repository,
            timeout: commandTimeout
        )
        var entries: [GitStatusEntry] = []
        for line in output.split(separator: "\n") {
            let s = String(line)
            guard s.count >= 4 else { continue }
            let x = s[s.startIndex]
            let y = s[s.index(after: s.startIndex)]
            // XY 后是一个空格，然后是路径。
            let pathStart = s.index(s.startIndex, offsetBy: 3)
            let rawPath = String(s[pathStart...])
            // 重命名/复制格式：old -> new，取目标路径。
            let path: String
            if let arrowRange = rawPath.range(of: " -> ") {
                path = String(rawPath[arrowRange.upperBound...])
            } else {
                path = rawPath
            }
            entries.append(GitStatusEntry(path: path, stagedStatus: x, worktreeStatus: y))
        }
        return entries
    }

    private static func validateRepository(_ repository: URL) throws {
        let repository = repository.standardizedFileURL
        guard FileManager.default.fileExists(
            atPath: repository.appendingPathComponent(".git").path
        ) else {
            throw Error.notARepository(repository)
        }
    }
}
