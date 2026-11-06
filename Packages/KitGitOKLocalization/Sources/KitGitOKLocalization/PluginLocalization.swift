import Foundation

/// 插件作用域的本地化服务。
///
/// 与上游 `LumiLocalizationKit.PluginLocalization` 保持同名同签名，
/// 以便插件侧的 `pluginLocalization.string(_:)` 调用点无需改动；
/// 实现改为转发到 `GitOKLocalization`，从而：
///
/// - 不受上游硬编码语言白名单限制（任意语言的 catalog 条目都能解析）；
/// - 支持应用内语言覆盖。
public struct PluginLocalization: @unchecked Sendable {
    /// 资源查找使用的 bundle（通常为插件模块的 `Bundle.module`）。
    public let bundle: Bundle

    /// 字符串表名，默认 `Localizable`。
    public let table: String

    public init(bundle: Bundle, table: String = GitOKLocalization.defaultTable) {
        self.bundle = bundle
        self.table = table
    }

    /// 按当前生效的语言解析本地化字符串，未命中时回退为原始 key。
    public func string(_ key: String, locale: Locale = .current) -> String {
        GitOKLocalization.string(key, bundle: bundle, table: table, locale: locale)
    }

    /// 与解析回退链一致的首选 locale。
    public func preferredLocale(_ locale: Locale = .current) -> Locale {
        GitOKLocalization.preferredLocale(locale)
    }
}
