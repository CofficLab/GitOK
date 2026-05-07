import Foundation
import OSLog

// MARK: - Git Detail 错误类型

/// Git Detail 插件相关的错误类型
enum GitDetailError: Error, LocalizedError {
    /// 刷新文件列表失败
    case refreshFileListFailed(underlying: Error)

    /// 丢弃文件更改失败
    case discardFileChangesFailed(underlying: Error)

    /// 丢弃所有更改失败
    case discardAllChangesFailed(underlying: Error)

    /// 获取文件差异失败
    case getFileDiffFailed(underlying: Error)

    /// 提交不存在
    case commitNotFound

    /// 项目无效
    case invalidProject

    /// 文件不存在
    case fileNotFound(String)

    /// 无效的配置值（LibGit2Swift 配置错误）
    case invalidConfigurationValue

    var errorDescription: String? {
        switch self {
        case .refreshFileListFailed:
            return "刷新文件列表失败"
        case .discardFileChangesFailed:
            return "丢弃文件更改失败"
        case .discardAllChangesFailed:
            return "丢弃所有更改失败"
        case .getFileDiffFailed:
            return "获取文件差异失败"
        case .commitNotFound:
            return "提交不存在"
        case .invalidProject:
            return "项目无效"
        case .fileNotFound(let path):
            return "文件不存在: \(path)"
        case .invalidConfigurationValue:
            return "Invalid configuration value"
        }
    }

    /// 将底层错误转换为 GitDetailError
    /// - Parameter error: 原始错误
    /// - Returns: 转换后的 GitDetailError
    static func from(_ error: Error, context: String = "") -> GitDetailError {
        // 检查是否是配置相关的错误
        if let nsError = error as NSError?,
           nsError.domain == "libgit2" || nsError.domain == "LibGit2Swift" {
            let localizedDescription = error.localizedDescription.lowercased()
            if localizedDescription.contains("invalid configuration") ||
               localizedDescription.contains("configuration value") {
                return .invalidConfigurationValue
            }
        }

        // 根据上下文选择合适的错误类型
        switch context {
        case "refreshFileList":
            return .refreshFileListFailed(underlying: error)
        case "discardFileChanges":
            return .discardFileChangesFailed(underlying: error)
        case "discardAllChanges":
            return .discardAllChangesFailed(underlying: error)
        case "getFileDiff":
            return .getFileDiffFailed(underlying: error)
        default:
            return .refreshFileListFailed(underlying: error)
        }
    }
}

// MARK: - 错误日志扩展

extension GitDetailError {
    /// 记录错误日志
    /// - Parameters:
    ///   - error: 错误实例
    ///   - context: 上下文信息
    ///   - logger: 日志记录器（可选）
    static func log(
        _ error: GitDetailError,
        context: String = "",
        logger: ((String) -> Void)? = nil
    ) {
        let message = "❌ \(error.localizedDescription)"
        let fullMessage = context.isEmpty ? message : "\(context): \(message)"
        
        if let logger = logger {
            logger(fullMessage)
        } else {
            os_log(.error, "\(fullMessage)")
        }
    }
}