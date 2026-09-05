import Foundation

/// Commit 风格选择器枚举
/// 定义提交消息的不同显示风格（从旧版 GitOK 原样迁移）。
public enum CommitStyle: String, CaseIterable, Sendable {
    case emoji = "Emoji Style"
    case plain = "Plain Style"
    case lowercase = "Lowercase Style"

    /// 显示标签
    public var label: String {
        rawValue
    }

    /// 是否包含 emoji
    public var includeEmoji: Bool {
        switch self {
        case .emoji:
            return true
        case .plain, .lowercase:
            return false
        }
    }

    /// 是否为小写格式
    public var isLowercase: Bool {
        switch self {
        case .lowercase:
            return true
        case .emoji, .plain:
            return false
        }
    }
}
