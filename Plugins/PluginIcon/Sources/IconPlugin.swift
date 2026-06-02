import Foundation
import GitOKCoreKit

public struct IconPlugin: GitOKPlugin {
    public static let shared = IconPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "IconPlugin",
        displayName: IconLocalization.string("plugin-display-name"),
        description: IconLocalization.string("plugin-description"),
        iconName: "photo",
        policy: .disabled,
        tableName: IconLocalization.table
    )

    private init() {}
}
