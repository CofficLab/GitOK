import Foundation
import KitGit
import ProviderGit

/// Git Diff 插件加载 diff 内容所需的最小能力。
///
/// `GitProviding` 有上百个成员，diff 面板只需要「读文本补丁」和「读二进制
/// blob」两组能力。此处收窄成一个窄协议，视图与加载器只面向它编程，
/// 测试也只需实现 4 个方法即可覆盖删除文件等边界场景。
protocol GitDiffContentCapability: Sendable {
    /// 读取某 commit 中指定文件的 unified diff。
    func loadDiff(
        commit: String,
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> String

    /// 读取工作区（未提交）中指定文件的 unified diff。
    func loadWorktreeDiff(
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> String

    /// 读取某 commit 中指定文件的原始字节。
    func loadBlobData(
        commit: String,
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> Data

    /// 读取工作区中指定文件的原始字节。
    func loadWorktreeFileData(
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> Data
}

/// 将 `GitProviding` 收窄成 diff 内容加载所需的能力。
struct GitDiffContentCapabilityAdapter: GitDiffContentCapability {
    private let git: any GitProviding

    init(git: any GitProviding) {
        self.git = git
    }

    func loadDiff(
        commit: String,
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> String {
        try git.loadDiff(
            commit: commit,
            filePath: filePath,
            in: repository,
            cancellation: cancellation
        )
    }

    func loadWorktreeDiff(
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> String {
        try git.loadWorktreeDiff(
            filePath: filePath,
            in: repository,
            cancellation: cancellation
        )
    }

    func loadBlobData(
        commit: String,
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> Data {
        try git.loadBlobData(
            commit: commit,
            filePath: filePath,
            in: repository,
            cancellation: cancellation
        )
    }

    func loadWorktreeFileData(
        filePath: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> Data {
        try git.loadWorktreeFileData(
            filePath: filePath,
            in: repository,
            cancellation: cancellation
        )
    }
}
