import Foundation

/// Git 配置辅助类
/// 使用 libgit2 读取 Git 配置信息
class GitConfig {
    /// 从指定仓库路径获取用户名
    static func getUserName(at path: String) throws -> String {
        try LibGit2.getConfig(key: "user.name", at: path)
    }
    
    /// 从指定仓库路径获取用户邮箱
    static func getUserEmail(at path: String) throws -> String {
        try LibGit2.getConfig(key: "user.email", at: path)
    }
}
