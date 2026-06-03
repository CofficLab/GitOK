import Foundation
#if os(iOS)
    import UIKit
#endif
#if os(macOS)
    import AppKit
#endif

/// Error扩展 - 提供错误处理和复制功能
public extension Error {
    /// 将错误信息复制到系统剪贴板
    /// 格式化的错误信息包含描述、失败原因、恢复建议等详细信息
    func copy() {
        var errorInfo = [String]()

        let L = MagicAlertLocalization.self

        errorInfo.append("\(L.string("Error")):\n\(localizedDescription)")

        if let failureReason = (self as? LocalizedError)?.failureReason {
            errorInfo.append("\n\(L.string("Reason")):\n\(failureReason)")
        }

        if let recoverySuggestion = (self as? LocalizedError)?.recoverySuggestion {
            errorInfo.append("\n\(L.string("Suggestion")):\n\(recoverySuggestion)")
        }

        // 添加 NSError 信息
        let nsError = self as NSError
        if nsError.domain != "NSCocoaErrorDomain" || nsError.code != 0 {
            errorInfo.append("\n\(L.string("Error")):\n\(L.string("Domain")): \(nsError.domain)\n\(L.string("Code")): \(nsError.code)")
        }

        if let helpAnchor = nsError.helpAnchor, !helpAnchor.isEmpty {
            errorInfo.append("\n\(L.string("Help")):\n\(helpAnchor)")
        }

        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            errorInfo.append("\n\(L.string("Underlying Error")): \(underlyingError.localizedDescription)")
        }

        let fullErrorInfo = errorInfo.joined(separator: "\n")

        // 复制到系统剪贴板
        #if os(iOS)
            UIPasteboard.general.string = fullErrorInfo
        #elseif os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(fullErrorInfo, forType: .string)
        #endif
    }

    /// 获取格式化的错误信息字符串（不复制到剪贴板）
    /// - Returns: 格式化后的错误信息
    func formattedDescription() -> String {
        var errorInfo = [String]()

        let L = MagicAlertLocalization.self

        errorInfo.append("\(L.string("Error")):\n\(localizedDescription)")

        if let failureReason = (self as? LocalizedError)?.failureReason {
            errorInfo.append("\n\(L.string("Reason")):\n\(failureReason)")
        }

        if let recoverySuggestion = (self as? LocalizedError)?.recoverySuggestion {
            errorInfo.append("\n\(L.string("Suggestion")):\n\(recoverySuggestion)")
        }

        // 添加 NSError 信息
        let nsError = self as NSError
        if nsError.domain != "NSCocoaErrorDomain" || nsError.code != 0 {
            errorInfo.append("\n\(L.string("Error")):\n\(L.string("Domain")): \(nsError.domain)\n\(L.string("Code")): \(nsError.code)")
        }

        if let helpAnchor = nsError.helpAnchor, !helpAnchor.isEmpty {
            errorInfo.append("\n\(L.string("Help")):\n\(helpAnchor)")
        }

        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            errorInfo.append("\n\(L.string("Underlying Error")): \(underlyingError.localizedDescription)")
        }

        return errorInfo.joined(separator: "\n")
    }
}
