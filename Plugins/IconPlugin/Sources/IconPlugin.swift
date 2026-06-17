import Foundation
import GitOKCoreKit
import SwiftUI

public enum IconPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "IconPlugin",
        displayName: IconLocalization.string("plugin-display-name"),
        description: IconLocalization.string("plugin-description"),
        iconName: "photo",
        policy: .alwaysOn,
        tableName: IconLocalization.table
    )

    @MainActor
    public static func detailPaneItems(context: GitOKPluginContext, tab: GitOKAppTab) -> [DetailPane] {
        guard tab == .icon else { return [] }
        return [
            DetailPane(
                id: metadata.id,
                view: AnyView(
                    IconDetailLayout(projectURL: context.projectURL)
                        .environmentObject(IconProvider())
                )
            ),
        ]
    }
}
