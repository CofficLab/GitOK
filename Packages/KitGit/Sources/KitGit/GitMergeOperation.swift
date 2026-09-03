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
}
