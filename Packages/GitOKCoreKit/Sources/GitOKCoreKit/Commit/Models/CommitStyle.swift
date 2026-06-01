import Foundation

/// Commit 风格选择器枚举
/// 定义提交消息的不同显示风格
public enum CommitStyle: String, CaseIterable {
    case emoji = "Emoji风格"
    case plain = "纯文本风格"
    case lowercase = "纯文本小写"

    /// 显示标签
    public var label: String {
        String(
            localized: String.LocalizationValue(rawValue),
            table: "GitCommit",
            bundle: .module
        )
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
