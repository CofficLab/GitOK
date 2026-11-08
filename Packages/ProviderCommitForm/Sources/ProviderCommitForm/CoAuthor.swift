import Foundation

/// 提交共同作者（Co-authored-by）。
/// 从旧版 GitOK 原样迁移（模型 + 磁盘存储）。
public struct CoAuthor: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var email: String

    public init(id: UUID = UUID(), name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }

    public var coAuthoredByLine: String {
        "Co-authored-by: \(name) <\(email)>"
    }

    public var displayText: String {
        "\(name) <\(email)>"
    }
}

/// 共同作者的持久化存储。
///
/// 存储位置遵循 Lumi 的插件存储规律：由 `StorageProviding.pluginDataDirectory(for:)`
/// 给出插件数据目录，共同作者列表写在该目录的 `co-authors.json` 里
/// （与 `ProviderCoAuthor` 的 `authors.json` 是两份独立数据：本存储服务于
/// 提交表单插件的全局协作者列表）。
///
/// ## 旧数据导入
///
/// 旧版实现把该列表存在 `UserDefaults`（key `GitOK_CoAuthors`）。本实现在注入目录时
/// 把旧值**一次性**导入 JSON，随后删除 UserDefaults 中的旧 key，
/// 保证此后磁盘是唯一数据源（导入后不再回读 UserDefaults）。
public final class CoAuthorStore: @unchecked Sendable {
    public static let shared = CoAuthorStore()

    /// 旧版 `UserDefaults` 的键名（一次性导入用）。
    public static let legacyDefaultsKey = "GitOK_CoAuthors"

    private let queue = DispatchQueue(
        label: "com.coffic.gitok.provider-commit-form.co-authors",
        qos: .userInitiated
    )

    /// 数据文件路径；未注入目录时为 nil（纯内存模式）。
    private var fileURL: URL?

    /// 内存缓存；未注入目录时即为唯一数据源。
    private var cached: [CoAuthor] = []

    /// 旧数据来源；测试可注入独立的 suite。
    private let legacyDefaults: UserDefaults

    public init(legacyDefaults: UserDefaults = .standard) {
        self.legacyDefaults = legacyDefaults
    }

    /// 注入插件数据目录，切换到磁盘存储并一次性导入旧值。
    ///
    /// - Parameter directory: 插件数据目录；不存在会自动创建。
    public func configure(directory: URL) {
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        queue.sync {
            let url = directory.appendingPathComponent("co-authors.json", isDirectory: false)
            fileURL = url
            // 磁盘已有记录时保留磁盘值；否则导入旧 UserDefaults 值。
            if let disk = readCoAuthorsLocked(from: url), !disk.isEmpty {
                cached = disk
                clearLegacyValueLocked()
            } else {
                importLegacyValueLocked()
                cached = readCoAuthorsLocked(from: url) ?? []
            }
        }
    }

    public func saveCoAuthors(_ coauthors: [CoAuthor]) {
        queue.sync {
            cached = coauthors
            guard let fileURL else { return }
            guard let data = try? JSONEncoder().encode(coauthors) else { return }
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    public func loadCoAuthors() -> [CoAuthor] {
        queue.sync {
            if let fileURL, let disk = readCoAuthorsLocked(from: fileURL) {
                return disk
            }
            return cached
        }
    }

    public func addCoAuthor(_ coauthor: CoAuthor) {
        var coauthors = loadCoAuthors()
        if !coauthors.contains(where: { $0.email == coauthor.email }) {
            coauthors.append(coauthor)
            saveCoAuthors(coauthors)
        }
    }

    public func removeCoAuthor(_ coauthor: CoAuthor) {
        var coauthors = loadCoAuthors()
        coauthors.removeAll { $0.id == coauthor.id }
        saveCoAuthors(coauthors)
    }

    public func updateCoAuthor(_ coauthor: CoAuthor) {
        var coauthors = loadCoAuthors()
        if let index = coauthors.firstIndex(where: { $0.id == coauthor.id }) {
            coauthors[index] = coauthor
            saveCoAuthors(coauthors)
        }
    }

    // MARK: - Legacy Import

    /// 把旧版 UserDefaults 中的协作者列表一次性导入 JSON。
    ///
    /// 必须在 `queue.sync` 内调用。
    private func importLegacyValueLocked() {
        guard let data = legacyDefaults.data(forKey: Self.legacyDefaultsKey),
              let coauthors = try? JSONDecoder().decode([CoAuthor].self, from: data),
              let fileURL,
              let encoded = try? JSONEncoder().encode(coauthors) else {
            legacyDefaults.removeObject(forKey: Self.legacyDefaultsKey)
            return
        }
        defer { legacyDefaults.removeObject(forKey: Self.legacyDefaultsKey) }
        try? encoded.write(to: fileURL, options: .atomic)
    }

    /// 移除旧 UserDefaults key（磁盘已有记录时调用，避免残留旧数据）。
    ///
    /// 必须在 `queue.sync` 内调用。
    private func clearLegacyValueLocked() {
        legacyDefaults.removeObject(forKey: Self.legacyDefaultsKey)
    }

    // MARK: - Disk Access

    /// 读取磁盘上的协作者列表；文件不存在时返回 nil。
    ///
    /// 必须在 `queue.sync` 内调用。
    private func readCoAuthorsLocked(from fileURL: URL) -> [CoAuthor]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode([CoAuthor].self, from: data)
    }
}
