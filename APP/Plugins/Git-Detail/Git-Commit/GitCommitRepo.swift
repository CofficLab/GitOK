import Foundation
import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// Git 提交仓库协议
/// 定义提交数据持久化的接口
protocol GitCommitRepoProtocol {
    func saveLastSelectedCommit(projectPath: String, commit: GitCommit)
    func getLastSelectedCommitHash(projectPath: String) -> String?
}

/// Git 提交仓库类
/// 负责管理项目最后选择的提交记录的持久化存储
class GitCommitRepo: GitCommitRepoProtocol, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "💾"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    static let shared = GitCommitRepo()

    /// UserDefaults 实例
    private let userDefaults = UserDefaults.standard

    private init() {}

    /// 保存项目的最后选择的commit
    /// - Parameters:
    ///   - projectPath: 项目路径
    ///   - commit: 选择的commit
    func saveLastSelectedCommit(projectPath: String, commit: GitCommit) {
        let key = GitCommitSelectionStore.key(for: projectPath)
        let commitData = GitCommitSelectionStore.commitData(
            hash: commit.hash,
            message: commit.message,
            author: commit.author,
            date: commit.date
        )

        userDefaults.set(commitData, forKey: key)

        if Self.verbose {
            os_log("\(self.t)已保存项目 \(projectPath) 的最后选择的commit: \(commit.hash)")
        }
    }

    /// 获取项目的最后选择的commit hash
    /// - Parameter projectPath: 项目路径
    /// - Returns: 最后选择的commit hash，如果没有则返回nil
    func getLastSelectedCommitHash(projectPath: String) -> String? {
        GitCommitSelectionStore.selectedHash(
            from: userDefaults.dictionary(forKey: GitCommitSelectionStore.key(for: projectPath))
        )
    }

    /// 清除项目的最后选择的commit
    /// - Parameter projectPath: 项目路径
    func clearLastSelectedCommit(projectPath: String) {
        let key = GitCommitSelectionStore.key(for: projectPath)
        userDefaults.removeObject(forKey: key)
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
