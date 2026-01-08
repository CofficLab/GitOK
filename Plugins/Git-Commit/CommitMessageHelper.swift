import Foundation
import MagicKit

/// Commit 消息辅助工具
struct CommitMessageHelper {

    /// 根据类别和风格生成默认消息
    static func defaultMessage(for category: CommitCategory, style: CommitStyle) -> String {
        let baseMessage = category.defaultMessage

        // 如果是小写风格，将首字母转换为小写
        if style.isLowercase {
            return lowercasedFirst(baseMessage)
        }

        return baseMessage
    }

    /// 将字符串的首字母转换为小写
    private static func lowercasedFirst(_ string: String) -> String {
        guard let first = string.first else {
            return string
        }

        return first.lowercased() + string.dropFirst()
    }
}
