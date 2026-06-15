import Foundation
import GitOKCoreKit
import SwiftUI

public enum OpenVSCodePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OpenVSCode",
        displayName: OpenVSCodePluginLocalization.string("Open VS Code"),
        description: OpenVSCodePluginLocalization.string("Open the current project folder in VS Code."),
        iconName: "chevron.left.forwardslash.chevron.right",
        order: 8400,
        policy: .optIn,
        tableName: OpenVSCodePluginLocalization.table
    )


    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(OpenVSCodeButton(projectURL: projectURL)))]
    }

    @MainActor
    public static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        Self.pluginIntroductionCard(
            footnote: VSCodeProjectLauncher.isInstalled ? nil : "VS Code is not installed on this Mac."
        )
    }
}

public enum OpenVSCodePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
