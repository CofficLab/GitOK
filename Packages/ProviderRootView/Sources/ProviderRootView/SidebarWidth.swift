import Foundation

/// 根布局左侧 sidebar 的宽度约束。
@MainActor
public struct SidebarWidth: Equatable, Sendable {
    public let minWidth: CGFloat
    public let idealWidth: CGFloat
    public let maxWidth: CGFloat

    public static let standard = Self(minWidth: 180, idealWidth: 220, maxWidth: 400)

    public init(minWidth: CGFloat, idealWidth: CGFloat, maxWidth: CGFloat) {
        let safeMin = minWidth.isFinite ? max(0, minWidth) : 0
        let safeMax: CGFloat
        if maxWidth.isFinite {
            safeMax = max(safeMin, maxWidth)
        } else {
            safeMax = .infinity
        }
        self.minWidth = safeMin
        self.maxWidth = safeMax
        self.idealWidth = Self.clamp(idealWidth, min: safeMin, max: safeMax)
    }

    public func withIdealWidth(_ width: CGFloat) -> Self {
        Self(minWidth: minWidth, idealWidth: width, maxWidth: maxWidth)
    }

    public func clamped(_ width: CGFloat) -> CGFloat {
        Self.clamp(width, min: minWidth, max: maxWidth)
    }

    private static func clamp(_ value: CGFloat, min minimum: CGFloat, max maximum: CGFloat) -> CGFloat {
        let safeValue = value.isFinite ? value : minimum
        return Swift.min(Swift.max(safeValue, minimum), maximum)
    }
}

/// sidebar 宽度偏好的持久化接口。
@MainActor
public protocol SidebarWidthStoring: AnyObject {
    func loadWidth() -> CGFloat?
    func saveWidth(_ width: CGFloat)
}

/// 使用插件数据目录下的 `settings.plist` 保存全局 sidebar 宽度。
///
/// 存储位置遵循 Lumi 的插件存储规律：由 `StorageProviding.pluginDataDirectory(for:)`
/// 给出 `<Application Support>/<bundleID>/db_<env>_v<major>/<pluginID>/`，
/// 宽度偏好写在该目录的 `settings.plist` 里。
///
/// ## 旧数据导入
///
/// 旧版实现把该偏好存在 `UserDefaults`（key 同 `legacyDefaultsKey`）。本实现会在
/// 初始化时把旧值**一次性**导入 `settings.plist`，随后删除 UserDefaults 中的旧 key，
/// 保证此后磁盘是唯一数据源（导入后不再回读 UserDefaults）。
@MainActor
public final class PluginDataSidebarWidthStore: SidebarWidthStoring {
    /// `settings.plist` 中的键名。
    public static let widthKey = "com.coffic.gitok.sidebar-width"

    /// 旧版 `UserDefaults` 的键名（一次性导入用）。
    public static let legacyDefaultsKey = "com.coffic.gitok.sidebar-width"

    /// 数据文件路径（`<插件数据目录>/settings.plist`）。
    private let fileURL: URL

    /// 旧数据来源；测试可注入独立的 suite。
    private let legacyDefaults: UserDefaults

    /// - Parameters:
    ///   - directory: 插件数据目录；不存在会自动创建。
    ///   - legacyDefaults: 旧版 UserDefaults 存储；默认 `.standard`。
    public init(directory: URL, legacyDefaults: UserDefaults = .standard) {
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        self.fileURL = directory.appendingPathComponent("settings.plist", isDirectory: false)
        self.legacyDefaults = legacyDefaults
        importLegacyValueIfNeeded()
    }

    public func loadWidth() -> CGFloat? {
        guard let value = readNumber(forKey: Self.widthKey) else { return nil }
        return value.isFinite && value > 0 ? CGFloat(value) : nil
    }

    public func saveWidth(_ width: CGFloat) {
        guard width.isFinite, width > 0 else { return }
        writeNumber(Double(width), forKey: Self.widthKey)
    }

    // MARK: - Legacy Import

    /// 把旧版 UserDefaults 中的宽度一次性导入 `settings.plist`。
    ///
    /// 规则：
    /// - 磁盘已有记录时**不**覆盖（磁盘值优先），但仍清掉旧 key；
    /// - 旧值非法（非有限数或 ≤ 0）时直接丢弃；
    /// - 无论成功与否都移除 UserDefaults 旧 key，避免重复导入。
    private func importLegacyValueIfNeeded() {
        // `double(forKey:)` 对缺失的 key 返回 0，因此先确认 key 确实存在。
        guard legacyDefaults.object(forKey: Self.legacyDefaultsKey) != nil else { return }
        let legacy = legacyDefaults.double(forKey: Self.legacyDefaultsKey)
        guard legacy.isFinite, legacy > 0 else {
            legacyDefaults.removeObject(forKey: Self.legacyDefaultsKey)
            return
        }
        defer { legacyDefaults.removeObject(forKey: Self.legacyDefaultsKey) }

        guard readNumber(forKey: Self.widthKey) == nil else { return }
        writeNumber(legacy, forKey: Self.widthKey)
    }

    // MARK: - Plist Access

    private func readNumber(forKey key: String) -> Double? {
        (readDict()[key] as? NSNumber)?.doubleValue
    }

    private func writeNumber(_ value: Double, forKey key: String) {
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

/// 纯内存的 sidebar 宽度存储。
///
/// 用于预览 / 测试场景：读写行为与磁盘实现一致，但不落盘。
@MainActor
public final class InMemorySidebarWidthStore: SidebarWidthStoring {
    private var width: CGFloat?

    public init(width: CGFloat? = nil) {
        self.width = width
    }

    public func loadWidth() -> CGFloat? {
        width
    }

    public func saveWidth(_ width: CGFloat) {
        guard width.isFinite, width > 0 else { return }
        self.width = width
    }
}
