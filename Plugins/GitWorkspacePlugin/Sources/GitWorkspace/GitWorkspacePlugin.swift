import Foundation
import GitOKCoreKit

public enum GitWorkspacePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitWorkspacePlugin",
        displayName: GitWorkspacePluginLocalization.string("Commit"),
        description: GitWorkspacePluginLocalization.string("Git commit management"),
        iconName: "arrow.up.arrow.down",
        policy: .disabled,
        tableName: GitWorkspacePluginLocalization.table
    )
}

public enum GitWorkspacePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
