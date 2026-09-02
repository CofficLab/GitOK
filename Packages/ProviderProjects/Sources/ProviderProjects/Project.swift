import Foundation

/// GitOK 项目（侧边栏项目列表的条目）。
///
/// 仅描述项目自身信息，不携带 Git 状态等运行时数据——
/// Git 相关能力由后续的 Git 服务层提供。
public struct Project: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    /// 项目根目录（本地路径）。
    public var url: URL
    /// 显示名称（默认取目录名）。
    public var title: String
    /// 是否置顶到列表最上方。
    public var isPinned: Bool
    /// 最近一次打开时间。
    public var lastOpenedAt: Date?

    public init(
        id: UUID = UUID(),
        url: URL,
        title: String? = nil,
        isPinned: Bool = false,
        lastOpenedAt: Date? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title ?? url.lastPathComponent
        self.isPinned = isPinned
        self.lastOpenedAt = lastOpenedAt
    }
}
