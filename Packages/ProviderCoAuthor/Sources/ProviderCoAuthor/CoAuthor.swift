import Foundation

/// 协作者信息（Co-authored-by）。
///
/// 一份协作者 = 一组「用户名 + 邮箱」，用于在提交时追加 `Co-authored-by` trailer。
/// 对齐旧版 `CoAuthor` 的语义，但迁移到独立 Provider 包以便多插件共享。
public struct CoAuthor: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var email: String

    public init(
        id: UUID = UUID(),
        name: String,
        email: String
    ) {
        self.id = id
        self.name = name
        self.email = email
    }

    /// `Co-authored-by: Name <email>` 格式的 trailer 行。
    public var coAuthoredByLine: String {
        "Co-authored-by: \(name) <\(email)>"
    }

    /// 展示文本：`Name <email>`。
    public var displayText: String {
        "\(name) <\(email)>"
    }
}
