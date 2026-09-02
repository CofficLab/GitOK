import Foundation

/// 某个 commit 中单个文件的一次变更。
public struct GitFileChange: Identifiable, Equatable, Sendable {
    public enum Status: String, Sendable {
        case added = "A"
        case deleted = "D"
        case modified = "M"
        case renamed = "R"
        case copied = "C"
        case unmerged = "U"
        case unknown = "?"
    }

    /// 当前（commit 内）路径。
    public let path: String
    /// 变更类型。
    public let status: Status
    /// 新增行数（numstat；二进制或不可解析时为 0）。
    public let addedLines: Int
    /// 删除行数（numstat；二进制或不可解析时为 0）。
    public let deletedLines: Int
    /// rename/copy 的原始路径（仅 R/C 有值）。
    public let oldPath: String?

    public var id: String { "\(status.rawValue):\(oldPath ?? ""):\(path)" }

    public init(path: String, status: Status, addedLines: Int, deletedLines: Int, oldPath: String? = nil) {
        self.path = path
        self.status = status
        self.addedLines = addedLines
        self.deletedLines = deletedLines
        self.oldPath = oldPath
    }

    public var displayPath: String {
        if let oldPath, status == .renamed || status == .copied {
            return "\(oldPath) → \(path)"
        }
        return path
    }
}

/// 通过 git CLI 加载单个 commit 的变动（文件列表 + unified diff）。
public enum GitDiffLoader {
    /// 读取指定 commit 涉及的文件变更（名称 + 状态 + 增删行）。
    ///
    /// 数据来自两条命令：
    /// - `git diff-tree --no-commit-id --name-status -r <hash>`：路径与状态；
    /// - `git show --format= --numstat <hash>`：每个文件的增删行数。
    /// 两者都带 `--root` 以覆盖根提交（无父提交）。
    public static func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange] {
        let nameStatus = try GitProcessRunner.run(
            ["diff-tree", "--no-commit-id", "--root", "--name-status", "-r", hash],
            in: repository
        )
        let numstat: String
        do {
            numstat = try GitProcessRunner.run(
                ["show", "--format=", "--numstat", hash],
                in: repository
            )
        } catch {
            numstat = ""
        }

        var stats: [String: (added: Int, deleted: Int)] = [:]
        for line in numstat.split(separator: "\n") {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard fields.count >= 3,
                  let added = Int(fields[0]),
                  let deleted = Int(fields[1])
            else { continue }
            // numstat 的 path 是"新路径"；rename 行含 "old => new"
            let path = fields[2...].joined(separator: "\t")
            stats[path] = (added, deleted)
        }

        var result: [GitFileChange] = []
        for line in nameStatus.split(separator: "\n") {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard fields.count >= 2 else { continue }
            let rawStatus = fields[0]
            guard let status = GitFileChange.Status(rawValue: String(rawStatus.prefix(1))) else { continue }

            var oldPath: String? = nil
            var path = fields[1]
            if (status == .renamed || status == .copied) && fields.count >= 3 {
                oldPath = path
                path = fields[2]
            }

            let stat = stats[path] ?? stats[fields[1]] ?? (0, 0)
            result.append(GitFileChange(
                path: path,
                status: status,
                addedLines: stat.added,
                deletedLines: stat.deleted,
                oldPath: oldPath
            ))
        }
        return result
    }

    /// 读取指定 commit 中某个文件的 unified diff（无颜色、含 `--` 头）。
    ///
    /// 使用 `git show --format= --no-color --find-renames <hash> -- <path>`。
    /// 对新增文件仍会返回其补丁（内容全部为 `+` 行）。
    public static func loadDiff(
        commit hash: String,
        filePath: String,
        in repository: URL
    ) throws -> String {
        let output = try GitProcessRunner.run(
            ["show", "--format=", "--no-color", "--find-renames", "--", hash, "--", filePath],
            in: repository
        )
        return output
    }
}
