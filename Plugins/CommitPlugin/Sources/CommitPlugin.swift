import Foundation
import GitOKCoreKit

public struct CommitPlugin: GitOKPlugin {
    public static let shared = CommitPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "CommitPlugin",
        displayName: CommitLocalization.string("Commit"),
        description: CommitLocalization.string("Git 提交管理"),
        iconName: "arrow.up.arrow.down",
        policy: .disabled,
        tableName: CommitLocalization.table
    )

    private init() {}
}
