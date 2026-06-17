import Foundation
import GitOKCoreKit
import SwiftUI

public enum BannerPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "BannerPlugin",
        displayName: BannerPluginLocalization.string("BannerPlugin"),
        description: "",
        order: 2,
        policy: .alwaysOn,
        tableName: BannerPluginLocalization.table
    )

    @MainActor
    public static func detailPaneItems(context: GitOKPluginContext, tab: String) -> [DetailPane] {
        guard tab == "Banner" else { return [] }
        return [
            DetailPane(
                id: metadata.id,
                view: AnyView(
                    BannerDetailLayout(projectURL: context.projectURL)
                        .environmentObject(BannerProvider.shared)
                )
            ),
        ]
    }
}

public enum BannerPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
