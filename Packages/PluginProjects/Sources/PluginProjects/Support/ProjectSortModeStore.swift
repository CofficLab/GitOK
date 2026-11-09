import Foundation

/// 项目排序偏好的持久化接口。
@MainActor
protocol ProjectSortModeStoring: AnyObject {
    func loadSortMode() -> ProjectSortMode?
    func saveSortMode(_ mode: ProjectSortMode)
}

/// 使用插件数据目录下的 `settings.plist` 保存项目侧边栏的展示方式。
///
/// 存储位置遵循 Lumi 的插件存储规律：由 `StorageProviding.pluginDataDirectory(for:)`
/// 给出 `<Application Support>/<bundleID>/db_<env>_v<major>/com.coffic.gitok.plugin.projects/`，
/// 排序偏好写在该目录的 `settings.plist` 里，与 `projects.json` 同级。
///
/// 排序偏好属于「界面偏好」而非项目数据，因此**不**写进 `projects.json`——
/// 换机器同步项目列表时不会把排序偏好一起带走，这是符合预期的行为。
///
/// ## 旧数据导入
///
/// 旧版实现把该偏好存在 `UserDefaults`（key 同 `sortModeKey`）。本实现会在
/// 初始化时把旧值**一次性**导入 `settings.plist`，随后删除 UserDefaults 中的旧 key，
/// 保证此后磁盘是唯一数据源（导入后不再回读 UserDefaults）。
@MainActor
final class PluginDataProjectSortModeStore: ProjectSortModeStoring {
    /// `settings.plist` 中的键名。
    static let sortModeKey = "com.coffic.gitok.project-sort-mode"

    /// 旧版 `UserDefaults` 的键名（一次性导入用）。
    static let legacyDefaultsKey = "com.coffic.gitok.project-sort-mode"

    /// 数据文件路径（`<插件数据目录>/settings.plist`）。
    private let fileURL: URL

    /// 旧数据来源；测试可注入独立的 suite。
    private let legacyDefaults: UserDefaults

    /// - Parameters:
    ///   - directory: 插件数据目录；不存在会自动创建。
    ///   - legacyDefaults: 旧版 UserDefaults 存储；默认 `.standard`。
    init(directory: URL, legacyDefaults: UserDefaults = .standard) {
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        self.fileURL = directory.appendingPathComponent("settings.plist", isDirectory: false)
        self.legacyDefaults = legacyDefaults
        importLegacyValueIfNeeded()
    }

    func loadSortMode() -> ProjectSortMode? {
        guard let raw = readString(forKey: Self.sortModeKey) else { return nil }
        return ProjectSortMode(rawValue: raw)
    }

    func saveSortMode(_ mode: ProjectSortMode) {
        writeString(mode.rawValue, forKey: Self.sortModeKey)
    }

    // MARK: - Legacy Import

    /// 把旧版 UserDefaults 中的排序偏好一次性导入 `settings.plist`。
    ///
    /// 规则：
    /// - 磁盘已有记录时**不**覆盖（磁盘值优先），但仍清掉旧 key；
    /// - 旧值无法识别为合法 `ProjectSortMode` 时直接丢弃；
    /// - 无论成功与否都移除 UserDefaults 旧 key，避免重复导入。
    private func importLegacyValueIfNeeded() {
        guard let legacy = legacyDefaults.string(forKey: Self.legacyDefaultsKey) else { return }
        defer { legacyDefaults.removeObject(forKey: Self.legacyDefaultsKey) }

        guard readString(forKey: Self.sortModeKey) == nil else { return }
        guard ProjectSortMode(rawValue: legacy) != nil else { return }
        writeString(legacy, forKey: Self.sortModeKey)
    }

    // MARK: - Plist Access

    private func readString(forKey key: String) -> String? {
        readDict()[key] as? String
    }

    private func writeString(_ value: String, forKey key: String) {
        var dict = readDict()
        dict[key] = value
        writeDict(dict)
    }

    private func readDict() -> [String: Any] {
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

    private func writeDict(_ dict: [String: Any]) {
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

/// 纯内存的排序偏好存储。
///
/// 用于预览 / 测试场景：读写行为与磁盘实现一致，但不落盘。
@MainActor
final class InMemoryProjectSortModeStore: ProjectSortModeStoring {
    private var mode: ProjectSortMode?

    init(mode: ProjectSortMode? = nil) {
        self.mode = mode
    }

    func loadSortMode() -> ProjectSortMode? {
        mode
    }

    func saveSortMode(_ mode: ProjectSortMode) {
        self.mode = mode
    }
}
