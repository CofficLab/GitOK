import Foundation

/// 协作者信息。
///
/// 一份协作者 = 一组「用户名 + 邮箱」，用于快速写入项目 / 仓库的 git 配置
/// （`user.name` / `user.email`）。支持保存多条协作者，其中至多一条可标记为
/// 默认（`isDefault`）。
public struct Collaborator: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var email: String
    public var isDefault: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.isDefault = isDefault
        self.createdAt = createdAt
    }

    /// 展示标题：优先姓名，姓名为空时退回邮箱。
    public var title: String {
        name.isEmpty ? email : name
    }
}
