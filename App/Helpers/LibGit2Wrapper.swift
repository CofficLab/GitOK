import Foundation
import Clibgit2
import OSLog

/// libgit2 C 库的 Swift 封装
/// 提供类型安全的接口和自动内存管理
class LibGit2 {
    /// 初始化 libgit2（应用启动时调用一次）
    static func initialize() {
        git_libgit2_init()
    }
    
    /// 清理 libgit2（应用退出时调用）
    static func shutdown() {
        git_libgit2_shutdown()
    }
    
    /// 获取 libgit2 最后一次发生的错误描述
    private static func lastError() -> String {
        if let error = git_error_last() {
            return String(cString: error.pointee.message)
        }
        return "No specific libgit2 error message"
    }

    /// 从指定仓库路径获取配置值
    /// - Parameters:
    ///   - key: 配置键（如 "user.name"）
    ///   - repoPath: 仓库路径
    /// - Returns: 配置值
    static func getConfig(key: String, at repoPath: String) throws -> String {
        os_log("🐚 LibGit2: Getting config for key: %{public}@ at path: %{public}@", key, repoPath)
        
        var repo: OpaquePointer? = nil
        var config: OpaquePointer? = nil
        var snapshot: OpaquePointer? = nil
        var outPtr: UnsafePointer<CChar>? = nil
        
        defer {
            if snapshot != nil { git_config_free(snapshot) }
            if config != nil { git_config_free(config) }
            if repo != nil { git_repository_free(repo) }
        }
        
        // 1. 尝试通过仓库获取配置
        let openResult = git_repository_open(&repo, repoPath)
        if openResult == 0, let repository = repo {
            if git_repository_config(&config, repository) == 0, let configuration = config {
                // 在 libgit2 1.x 中，获取字符串必须在 snapshot 上操作
                if git_config_snapshot(&snapshot, configuration) == 0, let configSnapshot = snapshot {
                    let getResult = git_config_get_string(&outPtr, configSnapshot, key)
                    if getResult == 0, let cString = outPtr {
                        let value = String(cString: cString)
                        os_log("🐚 LibGit2: Config found in repo: %{public}@ = %{public}@", key, value)
                        return value
                    }
                    os_log("🐚 LibGit2: Key not found in repo snapshot, code: %d", getResult)
                    // 清理 snapshot 以便后面 fallback 使用
                    git_config_free(snapshot)
                    snapshot = nil
                }
            }
        } else {
            os_log("🐚 LibGit2: Could not open repo at %{public}@, trying default config", repoPath)
        }
        
        // 2. Fallback: 直接读取默认全局配置
        os_log("🐚 LibGit2: Attempting fallback to default (global) config for key: %{public}@", key)
        var defaultConfig: OpaquePointer? = nil
        defer { if defaultConfig != nil { git_config_free(defaultConfig) } }
        
        if git_config_open_default(&defaultConfig) == 0, let configuration = defaultConfig {
            if git_config_snapshot(&snapshot, configuration) == 0, let configSnapshot = snapshot {
                let getResult = git_config_get_string(&outPtr, configSnapshot, key)
                if getResult == 0, let cString = outPtr {
                    let value = String(cString: cString)
                    os_log("🐚 LibGit2: Config found in default/global config: %{public}@ = %{public}@", key, value)
                    return value
                }
                os_log("🐚 LibGit2: Key not found in default snapshot: %{public}@", lastError())
            }
        }
        
        throw LibGit2Error.configKeyNotFound(key)
    }
}

/// libgit2 错误类型
enum LibGit2Error: Error, LocalizedError {
    case repositoryNotFound(String)
    case configNotFound
    case configKeyNotFound(String)
    case invalidValue
    
    var errorDescription: String? {
        switch self {
        case .repositoryNotFound(let path):
            return "Git repository not found at: \(path)"
        case .configNotFound:
            return "Failed to get git configuration"
        case .configKeyNotFound(let key):
            return "Configuration key not found: \(key)"
        case .invalidValue:
            return "Invalid configuration value"
        }
    }
}
