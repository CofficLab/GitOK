import Foundation
import KitGitOKLocalization

public enum WorktreeStatusLocalization {
    public static func string(_ key: String, bundle: Bundle, locale: Locale = .current) -> String {
        GitOKLocalization.string(key, bundle: bundle, locale: locale)
    }
}

/// 插件作用域的本地化服务（绑定本模块资源 bundle）。
public let pluginLocalization = PluginLocalization(bundle: .module)
