import Foundation

/// 本地 tag 的只读详情。
///
/// commit 列表里的 tag 胶囊宽度有限，长 tag 名会被截断；展开视图依赖这份详情
/// 展示完整的 tag 名、类型、指向的提交以及创建信息。
public struct GitTagDetail: Equatable, Sendable {
    /// tag 类型。
    public enum Kind: String, Equatable, Sendable {
        /// 轻量 tag：直接指向一个 commit，没有独立的 tag 对象。
        case lightweight
        /// 附注 tag：指向一个 tag 对象，可以带说明。
        case annotated
    }

    /// tag 名（不含 `refs/tags/` 前缀）。
    public let name: String
    /// tag 类型。
    public let kind: Kind
    /// tag 指向的 commit 完整哈希。
    public let targetHash: String
    /// tag 指向的 commit 主题（subject）。
    public let targetSubject: String
    /// 附注 tag 的说明；轻量 tag 为 nil。
    public let message: String?
    /// 创建者名称（附注 tag 为 tagger，轻量 tag 为 commit 作者）。
    public let creatorName: String?
    /// 创建者邮箱。
    public let creatorEmail: String?
    /// 创建时间。
    public let creatorDate: Date?

    public init(
        name: String,
        kind: Kind,
        targetHash: String,
        targetSubject: String,
        message: String? = nil,
        creatorName: String? = nil,
        creatorEmail: String? = nil,
        creatorDate: Date? = nil
    ) {
        self.name = name
        self.kind = kind
        self.targetHash = targetHash
        self.targetSubject = targetSubject
        self.message = message
        self.creatorName = creatorName
        self.creatorEmail = creatorEmail
        self.creatorDate = creatorDate
    }
}

/// 读取本地 tag 详情（只读，不产生任何仓库写入）。
public enum GitTagReader {
    /// 读取是按需触发的（用户点开 tag 胶囊），但仍不能让 git 子进程无限期阻塞 UI。
    private static let commandTimeout: TimeInterval = GitStatusLoader.commandTimeout
    /// 字段分隔符。`git log --format` 支持 `%x1f` 字节转义，用它避开
    /// commit 主题里出现制表符时把字段切碎的问题。
    private static let fieldSeparator = "\u{1f}"

    /// 读取指定 tag 的详情。
    ///
    /// tag 不存在、仓库路径无效或 git 调用失败时返回 nil（调用方应按
    /// “详情不可用”降级，而不是报错）。
    public static func detail(named name: String, in repository: URL) -> GitTagDetail? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let ref = "refs/tags/\(trimmed)"

        guard let tag = readTagMetadata(ref: ref, in: repository),
              let commit = readCommitMetadata(ref: ref, in: repository) else {
            return nil
        }

        let kind: GitTagDetail.Kind = tag.objectType == "tag" ? .annotated : .lightweight
        let targetHash = commit.hash.isEmpty ? tag.peeledObjectName : commit.hash
        let creatorName = kind == .annotated ? tag.taggerName : commit.authorName
        let creatorEmail = kind == .annotated ? tag.taggerEmail : commit.authorEmail
        let creatorDate = kind == .annotated ? tag.taggerDate : commit.authorDate

        return GitTagDetail(
            name: trimmed,
            kind: kind,
            targetHash: targetHash,
            targetSubject: commit.subject,
            message: kind == .annotated ? readAnnotatedMessage(objectName: tag.objectName, in: repository) : nil,
            creatorName: creatorName.isEmpty ? nil : creatorName,
            creatorEmail: creatorEmail.isEmpty ? nil : creatorEmail,
            creatorDate: creatorDate
        )
    }

    // MARK: - Metadata

    private struct TagMetadata {
        var objectType: String
        var objectName: String
        var peeledObjectName: String
        var taggerName: String
        var taggerEmail: String
        var taggerDate: Date?
    }

    private struct CommitMetadata {
        var hash: String
        var subject: String
        var authorName: String
        var authorEmail: String
        var authorDate: Date?
    }

    /// 读取 tag 自身的元信息（类型、对象哈希、tagger、创建时间）。
    private static func readTagMetadata(ref: String, in repository: URL) -> TagMetadata? {
        let format = "%(refname:short)%09%(objecttype)%09%(objectname)%09%(*objectname)"
            + "%09%(creatordate:iso-strict)%09%(taggername)%09%(taggeremail)"
        guard let output = try? GitProcessRunner.run(
            ["for-each-ref", "--format=\(format)", ref],
            in: repository,
            timeout: commandTimeout
        ) else { return nil }
        guard let line = output.split(separator: "\n", omittingEmptySubsequences: true).first
            .map(String.init) else { return nil }
        let fields = line.components(separatedBy: "\t")
        // 前五个字段（名字、类型、对象哈希、peeled 哈希、创建时间）都不含制表符，
        // 因此可以按位置安全读取。
        guard fields.count >= 5 else { return nil }
        return TagMetadata(
            objectType: fields[1],
            objectName: fields[2],
            peeledObjectName: fields[3],
            taggerName: fields.count > 5 ? fields[5] : "",
            // `%(taggeremail)` 带尖括号（`<a@b.com>`），与 `%(ae)` 的裸邮箱不一致，
            // 这里统一成裸邮箱，方便和 commit 作者邮箱对比。
            taggerEmail: fields.count > 6 ? Self.normalizedEmail(fields[6]) : "",
            taggerDate: parseISODate(fields[4])
        )
    }

    /// 读取 tag 指向的 commit 信息（哈希、主题、作者）。
    private static func readCommitMetadata(ref: String, in repository: URL) -> CommitMetadata? {
        let format = "%H%x1f%s%x1f%an%x1f%ae%x1f%aI"
        guard let output = try? GitProcessRunner.run(
            ["log", "-1", "--format=\(format)", ref],
            in: repository,
            timeout: commandTimeout
        ) else { return nil }
        let fields = output
            .trimmingCharacters(in: .newlines)
            .components(separatedBy: fieldSeparator)
        guard fields.count >= 5 else { return nil }
        return CommitMetadata(
            hash: fields[0],
            subject: fields[1],
            authorName: fields[2],
            authorEmail: fields[3],
            authorDate: parseISODate(fields[4])
        )
    }

    /// 读取附注 tag 的完整说明（tag 对象正文，空行之后的部分）。
    private static func readAnnotatedMessage(objectName: String, in repository: URL) -> String? {
        guard !objectName.isEmpty,
              let raw = try? GitProcessRunner.run(
                ["cat-file", "tag", objectName],
                in: repository,
                timeout: commandTimeout
              ),
              let headerEnd = raw.range(of: "\n\n") else {
            return nil
        }
        let message = raw[headerEnd.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? nil : message
    }

    /// 解析 git 的严格 ISO 时间（`2026-10-24T10:15:47+08:00`）。
    private static func parseISODate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: trimmed)
    }

    /// 去掉邮箱外层的尖括号。
    private static func normalizedEmail(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("<"), trimmed.hasSuffix(">"), trimmed.count >= 2 else {
            return trimmed
        }
        return String(trimmed.dropFirst().dropLast())
    }
}
