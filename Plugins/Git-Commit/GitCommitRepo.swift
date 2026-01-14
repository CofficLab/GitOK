import Foundation
import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// Git 提交仓库协议
/// 定义提交数据持久化的接口
protocol GitCommitRepoProtocol {
    func saveLastSelectedCommit(projectPath: String, commit: GitCommit)
    func getLastSelectedCommit(projectPath: String) -> GitCommit?
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

    /// 最后提交记录的键前缀
    private let lastCommitKeyPrefix = "Git.lastSelectedCommit_"

    private init() {}

    /// 保存项目的最后选择的commit
    /// - Parameters:
    ///   - projectPath: 项目路径
    ///   - commit: 选择的commit
    func saveLastSelectedCommit(projectPath: String, commit: GitCommit) {
        let key = getKey(for: projectPath)

        let commitData: [String: Any] = [
            "hash": commit.hash,
            "message": commit.message,
            "author": commit.author,
            "date": commit.date.timeIntervalSince1970, // 保存为时间戳
        ]

        userDefaults.set(commitData, forKey: key)

        if Self.verbose {
            os_log("\(self.t)已保存项目 \(projectPath) 的最后选择的commit: \(commit.hash)")
        }
    }

    /// 获取项目的最后选择的commit
    /// - Parameter projectPath: 项目路径
    /// - Returns: 最后选择的commit，如果没有则返回nil
    func getLastSelectedCommit(projectPath: String) -> GitCommit? {
        let key = getKey(for: projectPath)

        guard let commitData = userDefaults.dictionary(forKey: key),
              let _ = commitData["hash"] as? String,
              let _ = commitData["message"] as? String,
              let _ = commitData["author"] as? String,
              let _ = commitData["date"] as? TimeInterval,
              let _ = commitData["path"] as? String else {
            return nil
        }

        return nil
    }

    /// 清除项目的最后选择的commit
    /// - Parameter projectPath: 项目路径
    func clearLastSelectedCommit(projectPath: String) {
        let key = getKey(for: projectPath)
        userDefaults.removeObject(forKey: key)
    }

    /// 获取UserDefaults中的key
    /// - Parameter projectPath: 项目路径
    /// - Returns: 对应的key
    private func getKey(for projectPath: String) -> String {
        return lastCommitKeyPrefix + projectPath
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
