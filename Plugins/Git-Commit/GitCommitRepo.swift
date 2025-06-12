import Foundation
import MagicCore
import OSLog
import SwiftUI

protocol GitCommitRepoProtocol {
    func saveLastSelectedCommit(projectPath: String, commit: GitCommit)
    func getLastSelectedCommit(projectPath: String) -> GitCommit?
}

class GitCommitRepo: GitCommitRepoProtocol, SuperLog {
    static let shared = GitCommitRepo()

    private let userDefaults = UserDefaults.standard
    private let lastCommitKeyPrefix = "Git.lastSelectedCommit_"
    private let verbose = false

    var emoji = "💾"

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
        
        if verbose {
            os_log("\(self.t)已保存项目 \(projectPath) 的最后选择的commit: \(commit.hash)")
        }
    }

    /// 获取项目的最后选择的commit
    /// - Parameter projectPath: 项目路径
    /// - Returns: 最后选择的commit，如果没有则返回nil
    func getLastSelectedCommit(projectPath: String) -> GitCommit? {
        let key = getKey(for: projectPath)
    
        guard let commitData = userDefaults.dictionary(forKey: key),
              let hash = commitData["hash"] as? String,
              let message = commitData["message"] as? String,
              let author = commitData["author"] as? String,
              let dateTimestamp = commitData["date"] as? TimeInterval,
              let path = commitData["path"] as? String else {
            return nil
        }
    
        // 获取isHead属性，如果不存在则默认为false
        let isHead = (commitData["isHead"] as? Bool) ?? false
        let date = Date(timeIntervalSince1970: dateTimestamp)
    
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

#Preview {
    MagicUserDefaultsView(defaultSearchText: "Git.")
        .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
