import Foundation
import GitOKCoreKit
import SwiftUI

public enum OpenKiroPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OpenKiro",
        displayName: OpenKiroPluginLocalization.string("Open Kiro"),
        description: OpenKiroPluginLocalization.string("Open the current project folder in Kiro."),
        iconName: "water.waves",
        order: 8405,
        policy: .optIn,
        tableName: OpenKiroPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .openIn }

    @MainActor
    public static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        pluginAboutView(
            kind: .openIn,
            footnote: KiroProjectLauncher.isInstalled ? nil : openInUnavailableFootnote()
        )
    }


    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        guard let projectURL = context.projectURL,
              KiroProjectLauncher.isInstalled else { return [] }
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(OpenKiroButton(projectURL: projectURL)))]
    }
}

public enum OpenKiroPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
