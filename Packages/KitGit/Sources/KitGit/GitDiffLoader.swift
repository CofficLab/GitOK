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
    ///
    /// 注意：`--` 只能作为 `<hash>` 与 `<path>` 之间的分隔符出现一次；若在
    /// hash 前再加一个 `--`（`... -- <hash> -- <path>`），某些仓库中 git 会把
    /// 输出解析为空（实测 west-home-mini 等仓库返回空 diff），导致误判为
    /// "No Text Diff"。标准形式在任意仓库均稳定返回。
    public static func loadDiff(
        commit hash: String,
        filePath: String,
        in repository: URL
    ) throws -> String {
        let output = try GitProcessRunner.run(
            ["show", "--format=", "--no-color", "--find-renames", hash, "--", filePath],
            in: repository
        )
        return output
    }

    /// 读取工作区（未提交）中某个文件的 unified diff。
    ///
    /// 与 `loadDiff(commit:filePath:in:)`（commit 内某文件的 diff）对应，
    /// 用于"未选中 commit、只选中工作区变动文件"的场景：
    /// - 已跟踪文件（含暂存 / 未暂存）：`git diff HEAD -- <path>`，相对
    ///   最后一次提交展示该文件当前的全部改动；无 HEAD（如只有暂存、尚无
    ///   提交）时回退 `git diff --cached -- <path>`。
    /// - 未跟踪文件：`git diff --no-index /dev/null -- <path>`，整文件作为新增展示。
    /// - 未跟踪目录（路径以 `/` 结尾）：git 无法对目录生成文本 diff，返回空串，
    ///   由视图层提示 "No Text Diff"。
    public static func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String {
        if filePath.hasSuffix("/") {
            return ""
        }
        let entries = try GitStatusLoader.loadEntries(in: repository)
        let isUntracked = entries.contains { $0.path == filePath && $0.isUntracked }
        if isUntracked {
            // `git diff --no-index` 有差异时退出码为 1，属正常结果，需容忍。
            return try GitProcessRunner.run(
                ["diff", "--no-index", "/dev/null", "--", filePath],
                in: repository,
                successExitCodes: [0, 1]
            )
        }
        do {
            return try GitProcessRunner.run(
                ["diff", "HEAD", "--", filePath],
                in: repository
            )
        } catch {
            return try GitProcessRunner.run(
                ["diff", "--cached", "--", filePath],
                in: repository
            )
        }
    }
}
