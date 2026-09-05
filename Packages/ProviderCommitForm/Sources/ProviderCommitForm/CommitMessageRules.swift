import Foundation

/// Commit 消息组装规则（从旧版 GitOK 迁移核心逻辑）。
public enum CommitMessageRules {
    public static let fallbackSubject = "Auto Committed by GitOK"
    public static let fallbackCommitMessage = "Auto commit"

    /// 提交执行计划。
    public struct SubmitPlan: Equatable, Sendable {
        public let message: String
        public let addsAllFiles: Bool
        public let pushesAfterCommit: Bool

        public init(message: String, addsAllFiles: Bool, pushesAfterCommit: Bool) {
            self.message = message
            self.addsAllFiles = addsAllFiles
            self.pushesAfterCommit = pushesAfterCommit
        }
    }

    /// 根据类别与风格生成默认提交信息（不含类别前缀）。
    public static func defaultMessage(for category: CommitCategory, style: CommitStyle) -> String {
        let baseMessage = category.defaultMessage
        if style.isLowercase {
            return lowercasedFirst(baseMessage)
        }
        return baseMessage
    }

    /// 类别变化后应填入输入框的初始 subject。
    public static func subjectAfterCategoryChange(category: CommitCategory, style: CommitStyle) -> String {
        defaultMessage(for: category, style: style)
    }

    /// 风格变化后应填入输入框的初始 subject。
    public static func subjectAfterStyleChange(category: CommitCategory, style: CommitStyle) -> String {
        defaultMessage(for: category, style: style)
    }

    /// 组装最终 commit message：
    /// `"{category.text(style:)} {subject}"` + 可选 Co-authored-by 行。
    public static func formattedMessage(
        subject: String,
        category: CommitCategory,
        style: CommitStyle,
        coAuthors: [CoAuthor]
    ) -> String {
        let normalizedSubject = subject.isEmpty ? fallbackSubject : subject
        var message = "\(category.text(style: style))\(normalizedSubject)"

        if !coAuthors.isEmpty {
            message += "\n\n" + coAuthors.map(\.coAuthoredByLine).joined(separator: "\n")
        }

        return message
    }

    /// 组装提交计划：默认 add 全部；提交并推送时 `pushesAfterCommit = true`。
    public static func submitPlan(
        message: String,
        commitOnly: Bool
    ) -> SubmitPlan {
        SubmitPlan(
            message: message,
            addsAllFiles: true,
            pushesAfterCommit: !commitOnly
        )
    }

    /// 去掉首字符小写（lowercase 风格使用）。
    public static func lowercasedFirst(_ string: String) -> String {
        guard let first = string.first else { return string }
        return String(first).lowercased() + string.dropFirst()
    }
}
