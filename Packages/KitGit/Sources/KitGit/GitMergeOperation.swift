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
                LumiPluginLocalization.string("A conflicted file path is required.", bundle: .module)
            case .notMerging:
                LumiPluginLocalization.string("No merge is currently in progress.", bundle: .module)
            case .unresolvedConflicts:
                LumiPluginLocalization.string("Resolve all conflicts before continuing the merge.", bundle: .module)
            case .operationFailed(let message):
                String(format: LumiPluginLocalization.string("Merge operation failed: %@", bundle: .module), message)
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

    /// 列出冲突文件（`git status --porcelain` 中 index/worktree 为 U 的条目）。
    public static func conflictFiles(in repository: URL) -> [String] {
        guard let out = try? GitProcessRunner.run(
            ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
            in: repository
        ) else { return [] }
        var result: [String] = []
        for entry in out.split(separator: "\0") {
            let raw = String(entry)
            guard raw.count >= 4 else { continue }
            let index = raw[raw.index(raw.startIndex, offsetBy: 0)]
            let worktree = raw[raw.index(raw.startIndex, offsetBy: 1)]
            let path = String(raw.dropFirst(3))
            if index == "U" || worktree == "U" {
                result.append(path)
            }
        }
        return result
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
                _ = try GitProcessRunner.run(["checkout-index", "--stage=1", "--", path], in: repository)
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
