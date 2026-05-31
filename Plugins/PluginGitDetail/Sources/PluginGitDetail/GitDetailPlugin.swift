import Foundation
import GitOKPluginKit

public struct GitDetailPlugin: GitOKPackagedPlugin {
    public static let shared = GitDetailPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitDetailPlugin",
        displayName: PluginGitDetailLocalization.string("GitDetailPlugin"),
        description: "",
        order: 0,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginGitDetailLocalization.table
    )

    private init() {}
}

public enum PluginGitDetailLocalization {
    public static let table = "GitDetail"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
