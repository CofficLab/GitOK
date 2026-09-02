import Foundation

/// 一条 Git 提交记录。
public struct GitCommit: Identifiable, Equatable, Sendable {
    /// 完整 40 位哈希。
    public let hash: String
    /// 短哈希（默认 7 位）。
    public let shortHash: String
    /// 提交主题（subject，单行）。
    public let message: String
    /// 作者名。
    public let author: String
    /// 作者提交时间。
    public let date: Date

    public var id: String { hash }

    public init(hash: String, shortHash: String, message: String, author: String, date: Date) {
        self.hash = hash
        self.shortHash = shortHash
        self.message = message
        self.author = author
        self.date = date
    }
}
