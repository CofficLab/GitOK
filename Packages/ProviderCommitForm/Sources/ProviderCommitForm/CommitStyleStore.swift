import Foundation

/// 全局默认 commit 风格的持久化存储。
///
/// 存储位置遵循 Lumi 的插件存储规律：由 `StorageProviding.pluginDataDirectory(for:)`
/// 给出 `<Application Support>/<bundleID>/db_<env>_v<major>/<pluginID>/`，
/// 全局默认风格写在该目录的 `settings.plist` 里。
///
/// 该值是**共享设置**：提交表单 Provider 与「Commit Style」设置页都要读写它，
/// 因此两处统一使用 `GlobalCommitStyleStore.pluginDataDirectoryID` 指向的同一个目录，
/// 避免两处各写一份导致互相覆盖。
///
/// ## 旧数据导入
///
/// 旧版实现把该值存在 `UserDefaults`（key `GitOK_GlobalCommitStyle`）。本实现在
/// 注入目录时把旧值**一次性**导入 `settings.plist`，随后删除 UserDefaults 中的旧 key，
/// 保证此后磁盘是唯一数据源（导入后不再回读 UserDefaults）。
public final class GlobalCommitStyleStore: @unchecked Sendable {
    /// 全局共享实例。
    public static let shared = GlobalCommitStyleStore()

    /// 全局默认风格使用的插件数据目录 id。
    ///
    /// 提交表单 Provider 与「Commit Style」设置页共用此目录。
    public static let pluginDataDirectoryID = "com.coffic.gitok.plugin.commit-style"

    /// `settings.plist` 中的键名。
    public static let styleKey = "com.coffic.gitok.global-commit-style"

    /// 旧版 `UserDefaults` 的键名（一次性导入用）。
    public static let legacyDefaultsKey = "GitOK_GlobalCommitStyle"

    private let queue = DispatchQueue(
        label: "com.coffic.gitok.provider-commit-form.global-style",
        qos: .userInitiated
    )

    /// 数据文件路径；未注入目录时为 nil（纯内存模式）。
    private var fileURL: URL?

    /// 是否已完成过目录注入。重复注入时保留首次结果，避免两处装配互相覆盖。
    private var isConfigured = false

    /// 内存缓存；未注入目录时即为唯一数据源。
    private var cached: CommitStyle?

    /// 旧数据来源；测试可注入独立的 suite。
    private let legacyDefaults: UserDefaults

    public init(legacyDefaults: UserDefaults = .standard) {
        self.legacyDefaults = legacyDefaults
    }

    /// 注入插件数据目录，切换到磁盘存储并一次性导入旧值。
    ///
    /// 重复调用是**幂等**的：首次之后不再改写数据目录，避免提交表单 Provider 与
    /// 设置页分别注入时互相覆盖。
    ///
    /// - Parameter directory: 插件数据目录；不存在会自动创建。
    public func configure(directory: URL) {
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        queue.sync {
            guard !isConfigured else { return }
            isConfigured = true
            fileURL = directory.appendingPathComponent("settings.plist", isDirectory: false)
            // 磁盘已有记录时保留磁盘值；否则导入旧 UserDefaults 值。
            if readStyleFromDisk() == nil {
                importLegacyValueLocked()
            } else {
                clearLegacyValueLocked()
            }
            cached = readStyleFromDisk()
        }
    }

    /// 当前全局默认风格；无记录时回退 `.emoji`。
    public var current: CommitStyle {
        queue.sync {
            if let fileURL {
                if let style = readStyleLocked(from: fileURL) {
                    return style
                }
            }
            return cached ?? .emoji
        }
    }

    /// 设置全局默认风格。
    public func set(_ style: CommitStyle) {
        queue.sync {
            cached = style
            guard let fileURL else { return }
            var dict = readDictLocked(from: fileURL)
            dict[Self.styleKey] = style.rawValue
            writeDictLocked(dict, to: fileURL)
        }
    }

    // MARK: - Legacy Import

    /// 把旧版 UserDefaults 中的全局风格一次性导入 `settings.plist`。
    ///
    /// 必须在 `queue.sync` 内调用。
    private func importLegacyValueLocked() {
        guard let raw = legacyDefaults.string(forKey: Self.legacyDefaultsKey) else { return }
        defer { legacyDefaults.removeObject(forKey: Self.legacyDefaultsKey) }
        guard let style = CommitStyle(rawValue: raw), let fileURL else { return }
        var dict = readDictLocked(from: fileURL)
        dict[Self.styleKey] = style.rawValue
        writeDictLocked(dict, to: fileURL)
    }

    /// 移除旧 UserDefaults key（磁盘已有记录时调用，避免残留旧数据）。
    ///
    /// 必须在 `queue.sync` 内调用。
    private func clearLegacyValueLocked() {
        legacyDefaults.removeObject(forKey: Self.legacyDefaultsKey)
    }

    // MARK: - Plist Access

    /// 读取磁盘上的风格；必须在 `queue.sync` 内调用。
    private func readStyleFromDisk() -> CommitStyle? {
        guard let fileURL else { return nil }
        return readStyleLocked(from: fileURL)
    }

    private func readStyleLocked(from fileURL: URL) -> CommitStyle? {
        guard let raw = readDictLocked(from: fileURL)[Self.styleKey] as? String else { return nil }
        return CommitStyle(rawValue: raw)
    }

    private func readDictLocked(from fileURL: URL) -> [String: Any] {
        guard let data = try? Data(contentsOf: fileURL),
              let plist = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
              ),
              let dict = plist as? [String: Any]
        else {
            return [:]
        }
        return dict
    }

    private func writeDictLocked(_ dict: [String: Any], to fileURL: URL) {
        guard let data = try? PropertyListSerialization.data(
            fromPropertyList: dict,
            format: .binary,
            options: 0
        ) else {
            return
        }
        try? data.write(to: fileURL, options: .atomic)
    }
}

/// Commit 风格的全局默认存储。
///
/// 该值是**新项目 / 未记录项目的默认风格**，不再是全局唯一风格：
/// 每个项目的实际风格由 `DefaultCommitFormProvider` 按项目持久化，
/// 只有该项目尚无记录时才回退到这里。
///
/// 底层落在插件数据目录的 `settings.plist`（由宿主注入目录），
/// 不再使用 `UserDefaults`。
public enum CommitStyleStore {
    /// 当前全局默认风格。
    public static var current: CommitStyle {
        GlobalCommitStyleStore.shared.current
    }

    /// 设置全局默认风格。
    public static func set(_ style: CommitStyle) {
        GlobalCommitStyleStore.shared.set(style)
    }

    /// 注入插件数据目录（由宿主在装配阶段调用）。
    ///
    /// 注入时会一次性导入旧版 `UserDefaults` 中的全局风格。
    public static func configure(directory: URL) {
        GlobalCommitStyleStore.shared.configure(directory: directory)
    }
}

/// 每个项目的 Commit 风格存储。
///
/// 持久化为插件数据目录下的 JSON 文件，键为项目的标准化路径
/// （`standardizedFileURL.path`），与 `DefaultAutoPushProvider` 的按项目
/// 存储保持一致。
///
/// 未注入 `StorageProviding` 时退化为纯内存模式（测试 / 预览场景），
/// 读写仍然可用，只是不落盘。
@MainActor
public final class CommitStylePerProjectStore {
    /// 项目路径 → 风格 rawValue。
    private var styles: [String: String]
    private let fileURL: URL?

    /// - Parameter directory: 数据目录；传 `nil` 时仅使用内存。
    public init(directory: URL?) {
        guard let directory else {
            self.fileURL = nil
            self.styles = [:]
            return
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("commit-style-by-project.json")
        self.fileURL = url
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.styles = decoded
        } else {
            self.styles = [:]
        }
    }

    /// 读取指定项目的风格；无记录时返回 `nil`（由调用方决定回退策略）。
    public func style(for projectURL: URL) -> CommitStyle? {
        guard let raw = styles[key(for: projectURL)] else { return nil }
        return CommitStyle(rawValue: raw)
    }

    /// 写入指定项目的风格并持久化。
    public func setStyle(_ style: CommitStyle, for projectURL: URL) {
        styles[key(for: projectURL)] = style.rawValue
        save()
    }

    /// 项目键：标准化路径，避免同一仓库的不同写法产生重复记录。
    private func key(for projectURL: URL) -> String {
        projectURL.standardizedFileURL.path
    }

    private func save() {
        guard let fileURL, let data = try? JSONEncoder().encode(styles) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
