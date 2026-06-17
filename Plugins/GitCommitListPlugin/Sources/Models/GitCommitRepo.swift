import Foundation
import OSLog
import ProjectSupportKit

/// Git 提交仓库协议
/// 定义提交数据持久化的接口
public protocol GitCommitRepoProtocol {
    func saveLastSelectedCommit(
        projectPath: String,
        hash: String,
        message: String,
        author: String,
        date: Date
    )
    func getLastSelectedCommitHash(projectPath: String) -> String?
}

/// Git 提交仓库类
/// 负责管理项目最后选择的提交记录的持久化存储
public final class GitCommitRepo: GitCommitRepoProtocol, @unchecked Sendable {
    /// 是否启用详细日志输出
    public nonisolated static let verbose = false

    public static let shared = GitCommitRepo()

    /// UserDefaults 实例
    private let userDefaults = UserDefaults.standard

    private init() {}

    /// 保存项目的最后选择的commit
    /// - Parameters:
    ///   - projectPath: 项目路径
    ///   - hash: 选择的 commit hash
    ///   - message: 选择的 commit message
    ///   - author: 选择的 commit author
    ///   - date: 选择的 commit date
    public func saveLastSelectedCommit(
        projectPath: String,
        hash: String,
        message: String,
        author: String,
        date: Date
    ) {
        let key = GitCommitSelectionStore.key(for: projectPath)
        let commitData = GitCommitSelectionStore.commitData(
            hash: hash,
            message: message,
            author: author,
            date: date
        )

        userDefaults.set(commitData, forKey: key)

        if Self.verbose {
            os_log("已保存项目 \(projectPath) 的最后选择的commit: \(hash)")
        }
    }

    /// 获取项目的最后选择的commit hash
    /// - Parameter projectPath: 项目路径
    /// - Returns: 最后选择的commit hash，如果没有则返回nil
    public func getLastSelectedCommitHash(projectPath: String) -> String? {
        GitCommitSelectionStore.selectedHash(
            from: userDefaults.dictionary(forKey: GitCommitSelectionStore.key(for: projectPath))
        )
    }

    /// 清除项目的最后选择的commit
    /// - Parameter projectPath: 项目路径
    public func clearLastSelectedCommit(projectPath: String) {
        let key = GitCommitSelectionStore.key(for: projectPath)
        userDefaults.removeObject(forKey: key)
    }
}
