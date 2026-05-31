import Foundation
import GitOKCoreKit

public struct CommitPlugin: GitOKPlugin {
    public static let shared = CommitPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "CommitPlugin",
        displayName: PluginCommitLocalization.string("Commit"),
        description: PluginCommitLocalization.string("Git 提交管理"),
        iconName: "arrow.up.arrow.down",
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginCommitLocalization.table
    )

    private init() {}
}

public enum PluginCommitLocalization {
    public static let table = "GitCommit"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
