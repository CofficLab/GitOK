import Foundation

/// 合并操作与冲突检测（对齐旧版 GitRepositoryCLI 合并能力）。
public enum GitMergeOperation {
    /// 是否有进行中的合并（`.git/MERGE_HEAD` 存在）。
    public static func isMerging(in repository: URL) -> Bool {
        let gitDirURL = repository.appendingPathComponent(".git")
        let mergeHead = gitDirURL.appendingPathComponent("MERGE_HEAD")
        return FileManager.default.fileExists(atPath: mergeHead.path)
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
        try GitProcessRunner.run(["checkout", targetBranch], in: repository)
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
