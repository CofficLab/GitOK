import Foundation
import GitOKCoreKit

public struct CommitPlugin: GitOKPlugin {
    public static let shared = CommitPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "CommitPlugin",
        displayName: CommitPluginLocalization.string("Commit"),
        description: CommitPluginLocalization.string("Git commit management"),
        iconName: "arrow.up.arrow.down",
        policy: .alwaysOn,
        tableName: CommitPluginLocalization.table
    )

    private init() {}
}

public enum CommitPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
