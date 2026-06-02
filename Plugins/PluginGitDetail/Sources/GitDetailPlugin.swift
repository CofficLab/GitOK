import Foundation
import GitOKCoreKit

public struct GitDetailPlugin: GitOKPlugin {
    public static let shared = GitDetailPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitDetailPlugin",
        displayName: GitDetailLocalization.string("GitDetailPlugin"),
        description: "",
        order: 0,
        policy: .disabled,
        tableName: GitDetailLocalization.table
    )

    private init() {}
}
