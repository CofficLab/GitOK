import Foundation
import KitLocalization

/// FactoryGitOK 的运行时本地化。
///
/// 委托 `LumiLocalization` 按插件 bundle 的 Localizable 表查找。
/// 资源位于包根目录 `Resources/Localizable.xcstrings`，与 `Sources` 平级。
public enum LumiPluginLocalization {
    public static let bundle: Bundle = .module

    public static func string(_ key: String, bundle: Bundle, locale: Locale = .current) -> String {
        LumiLocalization.string(key, bundle: bundle, locale: locale)
    }
}
