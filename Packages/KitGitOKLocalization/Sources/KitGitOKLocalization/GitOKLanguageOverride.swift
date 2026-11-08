import Foundation

/// 应用内的界面语言覆盖。
///
/// 上游 `LumiLocalization` 只读取系统的 `Locale.preferredLanguages`，
/// 用户必须退出并重启 App 才能看到语言变化。本类型把「界面语言」
/// 提升为应用内的一等设置：
///
/// - 未设置覆盖时，行为与系统语言一致；
/// - 设置覆盖后，解析链收敛为「覆盖语言 + 源语言」，
///   未翻译的内容回落到英文（源语言），而不是悄悄换成系统语言。
///
/// 覆盖值持久化在 `UserDefaults`，并通过通知广播变更，
/// 订阅方据此刷新界面。
public final class GitOKLanguageOverride: @unchecked Sendable {
    /// 共享实例。生产代码只用这一个。
    public static let shared = GitOKLanguageOverride()

    /// 界面语言变更通知。
    ///
    /// 通知的 `object` 是发出变更的实例，订阅方据此过滤——
    /// 避免并行测试中不同实例的变更互相干扰。
    public static let didChangeNotification = Notification.Name("GitOKLanguageOverride.didChange")

    /// 持久化所用的 `UserDefaults` 键。
    public static let storageKey = "gitok.interfaceLanguage"

    private let defaults: UserDefaults
    private let lock = NSLock()
    private var cachedLanguage: String?

    /// 覆盖值变更时递增，用于作废字符串解析缓存。
    private var counter: UInt64 = 0

    /// - Parameter defaults: 偏好存储；测试可注入隔离实例。
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.cachedLanguage = defaults.string(forKey: Self.storageKey)
    }

    /// 当前覆盖的语言标识；`nil` 表示跟随系统语言。
    public var languageCode: String? {
        lock.lock()
        defer { lock.unlock() }
        return cachedLanguage
    }

    /// 覆盖值的版本号。变更时递增，用于作废缓存。
    public var generation: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return counter
    }

    /// 设置界面语言。
    ///
    /// - Parameter languageCode: 语言标识；传 `nil` 表示跟随系统语言。
    public func setLanguageCode(_ languageCode: String?) {
        let normalized = languageCode?.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = (normalized?.isEmpty == false) ? normalized : nil

        lock.lock()
        let changed = cachedLanguage != value
        cachedLanguage = value
        if changed {
            counter &+= 1
        }
        lock.unlock()

        guard changed else { return }

        if let value {
            defaults.set(value, forKey: Self.storageKey)
        } else {
            defaults.removeObject(forKey: Self.storageKey)
        }

        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }

    /// 当前界面语言是否由应用内覆盖决定。
    public var isOverridden: Bool {
        languageCode != nil
    }
}
