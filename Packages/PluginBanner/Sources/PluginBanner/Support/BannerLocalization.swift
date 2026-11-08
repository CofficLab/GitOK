import Foundation
import KitGitOKLocalization

/// PluginBanner 的运行时本地化。
///
/// 委托 `GitOKLocalization` 按插件 bundle 的 Localizable 表查找，
/// 源语言为英语（en），并随系统语言偏好回退到 `.xcstrings` catalog。
enum BannerLocalization {
    static func string(_ key: String, bundle: Bundle, locale: Locale = .current) -> String {
        GitOKLocalization.string(key, bundle: bundle, locale: locale)
    }
}

/// 插件作用域的本地化服务（绑定本模块资源 bundle）。
public let pluginLocalization = PluginLocalization(bundle: .module)
