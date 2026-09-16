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

/// 单次分页读取的 commit 文件变更。
public struct GitFileChangePage: Equatable, Sendable {
    public let offset: Int
    public let changes: [GitFileChange]
    public let hasMore: Bool

    public init(offset: Int, changes: [GitFileChange], hasMore: Bool) {
        self.offset = offset
        self.changes = changes
        self.hasMore = hasMore
    }
}

/// 通过 git CLI 加载单个 commit 的变动（文件列表 + unified diff）。
public enum GitDiffLoader {
    /// Diff enumeration can traverse large trees or invoke clean filters; bound
    /// each CLI stage so a stale detail request cannot keep loading forever.
    public static let commandTimeout: TimeInterval = 15

    private struct NulTokenParser {
        private var buffer = Data()

        mutating func append(_ data: Data, handle: (Data) -> Bool) -> Bool {
            buffer.append(data)
            while let separator = buffer.firstIndex(of: 0) {
                let token = Data(buffer[..<separator])
                buffer.removeSubrange(buffer.startIndex...separator)
                if !handle(token) {
                    return false
                }
            }
            return true
        }

        mutating func finish(handle: (Data) -> Bool) -> Bool {
            guard !buffer.isEmpty else { return true }
            let token = buffer
            buffer.removeAll(keepingCapacity: false)
            return handle(token)
        }
    }

    /// 统计 commit 的变更文件数，只保留计数，不保留路径数组。
    public static func countChanges(
        commit hash: String,
        in repository: URL,
        cancellation: GitProcessCancellation? = nil
    ) throws -> Int {
        if cancellation?.isCancelled == true { throw CancellationError() }
        var parser = NulTokenParser()
        var pendingStatus: String?
        var expectedPaths = 0
        var pathCount = 0

        try GitProcessRunner.stream(
            ["diff-tree", "--no-commit-id", "--root", "--name-status", "-r", "-z", "--find-renames", hash],
            in: repository,
            cancellation: cancellation,
            timeout: commandTimeout
        ) { data in
            parser.append(data) { token in
                let value = String(decoding: token, as: UTF8.self)
                if pendingStatus == nil {
                    pendingStatus = value
                    expectedPaths = value.first == "R" || value.first == "C" ? 2 : 1
                    return true
                }

                expectedPaths -= 1
                if expectedPaths == 0 {
                    pathCount += 1
                    pendingStatus = nil
                }
                return true
            }
        }
        if cancellation?.isCancelled == true { throw CancellationError() }
        _ = parser.finish { _ in true }
        return pathCount
    }

    /// 读取 commit 中指定偏移和数量的变更文件。
    ///
    /// 名称状态使用 NUL 分隔输出并在读完目标页后尽早终止 git；numstat
    /// 只扫描流，不把其它文件的统计信息放入内存。
    public static func loadChangesPage(
        commit hash: String,
        limit requestedLimit: Int,
        offset requestedOffset: Int,
        in repository: URL,
        cancellation: GitProcessCancellation? = nil
    ) throws -> GitFileChangePage {
        if cancellation?.isCancelled == true { throw CancellationError() }
        let limit = max(requestedLimit, 0)
        let offset = max(requestedOffset, 0)
        guard limit > 0 else {
            return GitFileChangePage(offset: offset, changes: [], hasMore: false)
        }

        var parser = NulTokenParser()
        var pendingStatus: String?
        var paths: [String] = []
        var changeIndex = 0
        var changes: [GitFileChange] = []
        var hasMore = false

        func consume(_ token: Data) -> Bool {
            let value = String(decoding: token, as: UTF8.self)
            if pendingStatus == nil {
                pendingStatus = value
                paths.removeAll(keepingCapacity: true)
                return true
            }

            paths.append(value)
            let statusValue = pendingStatus ?? "?"
            let isRename = statusValue.first == "R" || statusValue.first == "C"
            let expectedPaths = isRename ? 2 : 1
            guard paths.count == expectedPaths else { return true }

            if changeIndex >= offset {
                if changes.count < limit {
                    let status = GitFileChange.Status(rawValue: String(statusValue.prefix(1))) ?? .unknown
                    changes.append(
                        GitFileChange(
                            path: paths.last ?? "",
                            status: status,
                            addedLines: 0,
                            deletedLines: 0,
                            oldPath: isRename ? paths.first : nil
                        )
                    )
                } else {
                    hasMore = true
                    return false
                }
            }

            changeIndex += 1
            pendingStatus = nil
            paths.removeAll(keepingCapacity: true)
            return true
        }

        try GitProcessRunner.stream(
            ["diff-tree", "--no-commit-id", "--root", "--name-status", "-r", "-z", "--find-renames", hash],
            in: repository,
            cancellation: cancellation,
            timeout: commandTimeout
        ) { data in
            parser.append(data, handle: consume)
        }
        if cancellation?.isCancelled == true { throw CancellationError() }
        _ = parser.finish(handle: consume)

        guard !changes.isEmpty else {
            return GitFileChangePage(offset: offset, changes: [], hasMore: false)
        }

        var stats: [String: (added: Int, deleted: Int)] = [:]
        let targetPaths = Set(changes.flatMap { change in
            [change.path, change.oldPath].compactMap { $0 }
        })
        var foundPaths: Set<String> = []
        var numstatParser = NulTokenParser()
        var waitingRenamePaths = false
        var renameStat: (added: Int, deleted: Int)?
        var renamePaths: [String] = []

        func consumeNumstat(_ token: Data) -> Bool {
            let value = String(decoding: token, as: UTF8.self)
            if waitingRenamePaths {
                renamePaths.append(value)
                if renamePaths.count == 2 {
                    if let renameStat {
                        stats[renamePaths[1]] = renameStat
                        stats[renamePaths[0]] = renameStat
                        if targetPaths.contains(renamePaths[0]) { foundPaths.insert(renamePaths[0]) }
                        if targetPaths.contains(renamePaths[1]) { foundPaths.insert(renamePaths[1]) }
                    }
                    waitingRenamePaths = false
                    renamePaths.removeAll(keepingCapacity: true)
                }
                return !targetPaths.isSubset(of: foundPaths)
            }

            let fields = value.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
            guard fields.count == 3 else { return true }

            // Binary files use "-" for both counts; record them as zero so
            // they do not force a scan through the rest of a huge commit.
            let added = Int(fields[0]) ?? 0
            let deleted = Int(fields[1]) ?? 0

            let path = String(fields[2])
            if path.isEmpty {
                waitingRenamePaths = true
                renameStat = (added, deleted)
            } else {
                if targetPaths.contains(path) {
                    stats[path] = (added, deleted)
                    foundPaths.insert(path)
                }
            }
            return !targetPaths.isSubset(of: foundPaths)
        }

        try GitProcessRunner.stream(
            ["show", "--format=", "--numstat", "-z", "--find-renames", hash],
            in: repository,
            cancellation: cancellation,
            timeout: commandTimeout,
            onOutput: { data in numstatParser.append(data, handle: consumeNumstat) }
        )
        if cancellation?.isCancelled == true { throw CancellationError() }
        _ = numstatParser.finish(handle: consumeNumstat)

        let completedChanges = changes.map { change in
            let stat = stats[change.path] ?? stats[change.oldPath ?? ""] ?? (0, 0)
            return GitFileChange(
                path: change.path,
                status: change.status,
                addedLines: stat.added,
                deletedLines: stat.deleted,
                oldPath: change.oldPath
            )
        }
        return GitFileChangePage(offset: offset, changes: completedChanges, hasMore: hasMore)
    }

    /// 读取指定 commit 涉及的文件变更（名称 + 状态 + 增删行）。
    ///
    /// 数据来自两条命令：
    /// - `git diff-tree --no-commit-id --name-status -r <hash>`：路径与状态；
    /// - `git show --format= --numstat <hash>`：每个文件的增删行数。
    /// 两者都带 `--root` 以覆盖根提交（无父提交）。
    public static func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange] {
        let total = try countChanges(commit: hash, in: repository)
        guard total > 0 else { return [] }

        var result: [GitFileChange] = []
        var offset = 0
        let pageSize = 256
        while offset < total {
            let page = try loadChangesPage(
                commit: hash,
                limit: pageSize,
                offset: offset,
                in: repository
            )
            result.append(contentsOf: page.changes)
            guard !page.changes.isEmpty else { break }
            offset += page.changes.count
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
        in repository: URL,
        cancellation: GitProcessCancellation? = nil
    ) throws -> String {
        if cancellation?.isCancelled == true { throw CancellationError() }
        let output = try GitProcessRunner.run(
            ["show", "--format=", "--no-color", "--find-renames", hash, "--", filePath],
            in: repository,
            cancellation: cancellation,
            timeout: commandTimeout
        )
        if cancellation?.isCancelled == true { throw CancellationError() }
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
    public static func loadWorktreeDiff(
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation? = nil
    ) throws -> String {
        if cancellation?.isCancelled == true { throw CancellationError() }
        if filePath.hasSuffix("/") {
            return ""
        }
        let entries = try GitStatusLoader.loadEntries(in: repository, cancellation: cancellation)
        if cancellation?.isCancelled == true { throw CancellationError() }
        let isUntracked = entries.contains { $0.path == filePath && $0.isUntracked }
        if isUntracked {
            // `git diff --no-index` 有差异时退出码为 1，属正常结果，需容忍。
            return try GitProcessRunner.run(
                ["diff", "--no-index", "/dev/null", "--", filePath],
                in: repository,
                successExitCodes: [0, 1],
                cancellation: cancellation,
                timeout: commandTimeout
            )
        }
        do {
            return try GitProcessRunner.run(
                ["diff", "HEAD", "--", filePath],
                in: repository,
                cancellation: cancellation,
                timeout: commandTimeout
            )
        } catch {
            if cancellation?.isCancelled == true { throw CancellationError() }
            return try GitProcessRunner.run(
                ["diff", "--cached", "--", filePath],
                in: repository,
                cancellation: cancellation,
                timeout: commandTimeout
            )
        }
    }
}
