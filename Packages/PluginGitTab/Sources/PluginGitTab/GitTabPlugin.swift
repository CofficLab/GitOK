import Foundation
import GitOKPluginKit

public struct GitTabPlugin: GitOKPackagedPlugin {
    public static let shared = GitTabPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitTabPlugin",
        displayName: PluginGitTabLocalization.string("Git"),
        description: PluginGitTabLocalization.string("Git version control"),
        iconName: "arrow.up.arrow.down",
        order: 0,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginGitTabLocalization.table
    )

    private init() {}

    public func tabItem() -> String? {
        Self.metadata.displayName
    }
}

public enum PluginGitTabLocalization {
    public static let table = "GitTab"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
