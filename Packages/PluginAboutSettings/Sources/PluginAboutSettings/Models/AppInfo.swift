import Foundation

/// 应用身份与版本信息。
///
/// 原先这些读取内嵌在 `AboutView` 的私有计算属性中，只能依赖真实
/// `Bundle.main`；抽为可注入 bundle 的值类型后，字段缺失与类型不符等
/// 分支都能直接断言。
struct AppInfo: Equatable {
    // MARK: - Info.plist 键名

    static let nameKey = "CFBundleName"
    static let versionKey = "CFBundleShortVersionString"
    static let buildKey = "CFBundleVersion"

    // MARK: - 缺省占位

    /// 应用名缺失时使用的产品名。
    static let defaultName = "GitOK"
    /// 版本号 / 构建号缺失时使用的占位符。
    static let placeholder = "-"

    // MARK: - 字段

    /// 应用显示名。
    let name: String
    /// 用户可见版本号。
    let version: String
    /// 构建号。
    let build: String
    /// Bundle 标识符。
    let bundleIdentifier: String

    init(name: String, version: String, build: String, bundleIdentifier: String) {
        self.name = name
        self.version = version
        self.build = build
        self.bundleIdentifier = bundleIdentifier
    }

    /// 从 bundle 读取应用信息，缺失字段回落到占位值。
    ///
    /// 非字符串类型的 Info.plist 值同样视为缺失（例如某些构建把版本写成数字）。
    init(bundle: Bundle = .main) {
        self.name = bundle.object(forInfoDictionaryKey: Self.nameKey) as? String
            ?? Self.defaultName
        self.version = bundle.object(forInfoDictionaryKey: Self.versionKey) as? String
            ?? Self.placeholder
        self.build = bundle.object(forInfoDictionaryKey: Self.buildKey) as? String
            ?? Self.placeholder
        self.bundleIdentifier = bundle.bundleIdentifier ?? Self.placeholder
    }
}
