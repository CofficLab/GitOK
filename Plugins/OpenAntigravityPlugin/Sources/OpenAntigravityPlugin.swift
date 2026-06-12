import Foundation
import GitOKCoreKit
import SwiftUI

public enum OpenAntigravityPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OpenAntigravity",
        displayName: OpenAntigravityPluginLocalization.string("Open Antigravity"),
        description: OpenAntigravityPluginLocalization.string("Open the current project folder in Antigravity."),
        iconName: "paperplane",
        order: 8406,
        policy: .optIn,
        tableName: OpenAntigravityPluginLocalization.table
    )


    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(OpenAntigravityButton(projectURL: projectURL)))]
    }
}

public enum OpenAntigravityPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
