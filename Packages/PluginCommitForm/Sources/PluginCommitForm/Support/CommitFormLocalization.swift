import Foundation
import KitLocalization

/// PluginCommitForm 本地化入口。
///
/// 基于 `KitLocalization` 的运行时本地化查找（兼容 SPM plugin bundle，
/// 从 `Resources/Localizable.xcstrings` catalog 读取），默认语言为英语（en）。
/// 视图层通过 `loc(_:)` helper 调用本入口获取当前语言的文案。
public enum CommitFormLocalization {
    public static func string(_ key: String, bundle: Bundle, locale: Locale = .current) -> String {
        LumiLocalization.string(key, bundle: bundle, locale: locale)
    }
}
