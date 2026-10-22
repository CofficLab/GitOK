import Foundation
import KitGit
@testable import PluginGitDiff

/// 可脚本化的 diff 内容能力替身。
///
/// 只实现 `GitDiffContentCapability` 的 4 个读取方法，测试可分别控制
/// 「文本补丁」「blob 字节」「是否抛错」，从而覆盖删除文件等边界场景。
final class ScriptedDiffContentCapability: GitDiffContentCapability, @unchecked Sendable {
    /// 文本补丁：key 为 "commitHash:path" 或 "worktree:path"。
    var diffs: [String: String] = [:]
    /// blob 字节：key 同上。
    var blobs: [String: Data] = [:]
    /// 按 key 抛出的错误。
    var errors: [String: Error] = [:]
    /// 已记录调用，便于断言「加载器没有多余地读取 blob」。
    private(set) var recordedCalls: [String] = []

    private func key(commit: String?, path: String) -> String {
        "\(commit ?? "worktree"):\(path)"
    }

    func loadDiff(
        commit: String,
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> String {
        let key = key(commit: commit, path: filePath)
        recordedCalls.append("loadDiff(\(key))")
        if let error = errors[key] { throw error }
        return diffs[key] ?? ""
    }

    func loadWorktreeDiff(
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> String {
        let key = key(commit: nil, path: filePath)
        recordedCalls.append("loadWorktreeDiff(\(key))")
        if let error = errors[key] { throw error }
        return diffs[key] ?? ""
    }

    func loadBlobData(
        commit: String,
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> Data {
        let key = key(commit: commit, path: filePath)
        recordedCalls.append("loadBlobData(\(key))")
        if let error = errors[key] { throw error }
        guard let data = blobs[key] else {
            // 与 `git cat-file blob` 的行为一致：路径不存在时退出码非 0。
            throw GitDiffLoaderError.invalidFilePath(filePath)
        }
        return data
    }

    func loadWorktreeFileData(
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> Data {
        let key = key(commit: nil, path: filePath)
        recordedCalls.append("loadWorktreeFileData(\(key))")
        if let error = errors[key] { throw error }
        guard let data = blobs[key] else {
            throw GitDiffLoaderError.invalidFilePath(filePath)
        }
        return data
    }
}

/// 测试用 commit 工厂。
enum DiffTestFixtures {
    static func commit(
        hash: String,
        parents: [String] = []
    ) -> GitCommit {
        GitCommit(
            hash: hash,
            shortHash: String(hash.prefix(7)),
            message: "message",
            author: "author",
            date: Date(timeIntervalSince1970: 0),
            parentHashes: parents
        )
    }
}
