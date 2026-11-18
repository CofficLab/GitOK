import Foundation

public enum GitMergeFileVersion: String, CaseIterable, Equatable, Sendable {
    case base
    case ours
    case theirs

    public var stageNumber: Int {
        switch self {
        case .base: 1
        case .ours: 2
        case .theirs: 3
        }
    }
}

/// 未合并索引条目的形状。
///
/// 冲突弹层需要区分「必须人工做决定」和「合并结果已经确定」两类冲突：
/// 只保留一边、或两边都不再保留文件的条目，暂存/移除后即可完成合并；
/// 只有两边都保留文件的条目才需要内容级解决。
public struct GitConflictEntry: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        /// 两边都保留了文件，需要内容级解决。
        case content
        /// 只有一边新增了文件（index 只有 stage 2 或 3），合并结果由该边决定。
        case oneSided
        /// 两边都不再保留文件，只剩 base 阶段（libgit2 合并会留下这种条目）。
        case bothDeleted
        /// 一边删除、另一边修改（index 为 1+2 或 1+3），需要用户决定保留删除还是保留修改。
        case deleteModify
        /// 后端无法给出形状，调用方应按未解决处理。
        case unknown
    }

    public let path: String
    public let kind: Kind

    public init(path: String, kind: Kind) {
        self.path = path
        self.kind = kind
    }
}

/// 合并操作与冲突检测（对齐旧版 GitRepositoryCLI 合并能力）。
public enum GitMergeOperation {
    public enum Error: Swift.Error, LocalizedError {
        case invalidPath
        case notMerging
        case unresolvedConflicts
        case operationFailed(String)

        public var errorDescription: String? {
            switch self {
            case .invalidPath:
                pluginLocalization.string("A conflicted file path is required.")
            case .notMerging:
                pluginLocalization.string("No merge is currently in progress.")
            case .unresolvedConflicts:
                pluginLocalization.string("Resolve all conflicts before continuing the merge.")
            case .operationFailed(let message):
                String(format: pluginLocalization.string("Merge operation failed: %@"), message)
            }
        }
    }

    /// 是否有进行中的合并（`.git/MERGE_HEAD` 存在）。
    public static func isMerging(in repository: URL) -> Bool {
        let gitDirURL = repository.appendingPathComponent(".git")
        let mergeHead = gitDirURL.appendingPathComponent("MERGE_HEAD")
        return FileManager.default.fileExists(atPath: mergeHead.path)
    }

    /// 是否存在需要解决冲突的 Git 操作（合并或 Cherry-pick）。
    public static func hasConflictOperation(in repository: URL) -> Bool {
        isMerging(in: repository) || GitCherryPickOperation.status(in: repository).isCherryPicking
    }

    /// 列出冲突文件（`git ls-files -u` 中的未合并路径）。
    public static func conflictFiles(in repository: URL) -> [String] {
        conflictEntries(in: repository).map(\.path)
    }

    /// 列出冲突条目及其形状（按路径排序）。
    ///
    /// 未合并条目最多有 stage 1（base）/ 2（ours）/ 3（theirs）三个版本：
    /// 只有 base 时说明两边都删除了该文件；只有一侧时说明该侧新增了文件；
    /// 两侧都在时才是内容级冲突。base 加一侧是「一边删除、一边修改」，
    /// 必须由用户决定，不能自动挑边。
    public static func conflictEntries(in repository: URL) -> [GitConflictEntry] {
        guard let out = try? GitProcessRunner.run(["ls-files", "-u", "-z"], in: repository) else {
            return []
        }
        return conflictEntries(fromUnmergedListing: out)
    }

    /// 解析 `git ls-files -u -z` 的输出。
    ///
    /// 每条记录形如 `100644 <oid> 2\tpath`。暴露给测试，便于用合成输出
    /// 覆盖 rare 的索引形状。
    static func conflictEntries(fromUnmergedListing listing: String) -> [GitConflictEntry] {
        var stagesByPath: [String: Set<Int>] = [:]
        for record in listing.split(separator: "\0") {
            let raw = String(record)
            guard let tab = raw.firstIndex(of: "\t") else { continue }
            let header = raw[..<tab].split(separator: " ")
            guard header.count >= 3, let stage = Int(header[2]) else { continue }
            let path = String(raw[raw.index(after: tab)...])
            stagesByPath[path, default: []].insert(stage)
        }
        return stagesByPath.keys.sorted().map { path in
            GitConflictEntry(path: path, kind: kind(forStages: stagesByPath[path] ?? []))
        }
    }

    private static func kind(forStages stages: Set<Int>) -> GitConflictEntry.Kind {
        switch stages {
        case [1]:
            return .bothDeleted
        case [2], [3]:
            return .oneSided
        case [1, 2], [1, 3]:
            return .deleteModify
        case [2, 3], [1, 2, 3]:
            return .content
        default:
            return .unknown
        }
    }

    /// 合并 `sourceBranch` 到 `targetBranch`（先 checkout 目标分支再合并）。
    /// 返回合并输出；若存在冲突，抛出 `GitMergeError.conflict` 并保留冲突状态，
    /// 调用方可读取 `conflictFiles(in:)` 处理冲突。
    public static func mergeBranches(
        repository: URL,
        sourceBranch: String,
        targetBranch: String
    ) throws -> String {
        _ = try GitProcessRunner.run(["checkout", targetBranch], in: repository)
        do {
            return try GitProcessRunner.run(["merge", sourceBranch], in: repository)
        } catch {
            if isMerging(in: repository) {
                throw GitMergeError.conflict(
                    message: error.localizedDescription,
                    files: conflictFiles(in: repository)
                )
            }
            throw error
        }
    }

    /// 读取冲突文件的 base、ours 或 theirs 版本。
    public static func mergeFileContent(
        path: String,
        version: GitMergeFileVersion,
        in repository: URL
    ) throws -> String {
        let path = try validatedPath(path)
        guard hasConflictOperation(in: repository) else { throw Error.notMerging }
        let stage: Int
        switch version {
        case .base: stage = 1
        case .ours: stage = 2
        case .theirs: stage = 3
        }
        do {
            return try GitProcessRunner.run(["show", ":\(stage):\(path)"], in: repository)
        } catch {
            throw Error.operationFailed(Self.message(for: error))
        }
    }

    /// 读取指定冲突文件的 combined diff。
    public static func mergeFileDiff(path: String, in repository: URL) throws -> String {
        let path = try validatedPath(path)
        guard hasConflictOperation(in: repository) else { throw Error.notMerging }
        do {
            return try GitProcessRunner.run(["diff", "--cc", "--", path], in: repository)
        } catch {
            throw Error.operationFailed(Self.message(for: error))
        }
    }

    /// 选择冲突文件的某个版本并将其加入暂存区。
    public static func checkoutMergeFileVersion(
        path: String,
        version: GitMergeFileVersion,
        in repository: URL
    ) throws {
        let path = try validatedPath(path)
        guard hasConflictOperation(in: repository) else { throw Error.notMerging }
        do {
            switch version {
            case .base:
                // `checkout-index` 默认拒绝覆盖工作区已存在的文件，而冲突文件
                // 必然存在。缺省行为会让 “Use Base” 永远失败，因此必须 --force。
                _ = try GitProcessRunner.run(["checkout-index", "--force", "--stage=1", "--", path], in: repository)
            case .ours:
                _ = try GitProcessRunner.run(["checkout", "--ours", "--", path], in: repository)
            case .theirs:
                _ = try GitProcessRunner.run(["checkout", "--theirs", "--", path], in: repository)
            }
            _ = try GitProcessRunner.run(["add", "--", path], in: repository)
        } catch {
            throw Error.operationFailed(Self.message(for: error))
        }
    }

    /// 在所有冲突已解决并暂存后完成当前合并。
    @discardableResult
    public static func continueMerge(in repository: URL) throws -> String {
        guard isMerging(in: repository) else { throw Error.notMerging }
        guard conflictFiles(in: repository).isEmpty else { throw Error.unresolvedConflicts }
        do {
            return try GitProcessRunner.run(["commit", "--no-edit"], in: repository)
        } catch {
            throw Error.operationFailed(Self.message(for: error))
        }
    }

    /// 放弃当前合并并恢复到合并前状态。
    @discardableResult
    public static func abortMerge(in repository: URL) throws -> String {
        guard isMerging(in: repository) else { throw Error.notMerging }
        do {
            return try GitProcessRunner.run(["merge", "--abort"], in: repository)
        } catch {
            throw Error.operationFailed(Self.message(for: error))
        }
    }

    /// 若合并没有未解决冲突，则尝试完成遗留的合并状态。
    @discardableResult
    public static func finalizeMergeIfNeeded(in repository: URL) throws -> String? {
        guard isMerging(in: repository), conflictFiles(in: repository).isEmpty else { return nil }
        return try continueMerge(in: repository)
    }

    private static func validatedPath(_ path: String) throws -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Error.invalidPath }
        return trimmed
    }

    private static func message(for error: Swift.Error) -> String {
        (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
    }
}

/// 合并相关错误。
public enum GitMergeError: Error, LocalizedError, Sendable {
    case conflict(message: String, files: [String])

    public var errorDescription: String? {
        switch self {
        case let .conflict(message, files):
            if files.isEmpty {
                return "Merge paused with conflicts: \(message)"
            }
            return "Merge paused with \(files.count) conflict file(s): \(message)"
        }
    }
}
