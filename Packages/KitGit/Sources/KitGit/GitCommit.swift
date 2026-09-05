import Foundation

/// 一条 git 提交。
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
    /// 父提交完整哈希（按 git log `%P` 顺序）。
    public let parentHashes: [String]
    /// 指向该提交的 tag 名（来自 `%D` 解析，仅 tag: 前缀）。
    public let tags: [String]

    public var id: String { hash }

    public init(
        hash: String,
        shortHash: String,
        message: String,
        author: String,
        date: Date,
        parentHashes: [String] = [],
        tags: [String] = []
    ) {
        self.hash = hash
        self.shortHash = shortHash
        self.message = message
        self.author = author
        self.date = date
        self.parentHashes = parentHashes
        self.tags = tags
    }
}
