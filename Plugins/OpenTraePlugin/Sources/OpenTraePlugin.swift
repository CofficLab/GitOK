import Foundation
import GitOKCoreKit
import SwiftUI

public enum OpenTraePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OpenTrae",
        displayName: OpenTraePluginLocalization.string("Open Trae"),
        description: OpenTraePluginLocalization.string("Open the current project folder in Trae."),
        iconName: "brain",
        order: 8404,
        policy: .optIn,
        tableName: OpenTraePluginLocalization.table
    )


    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        guard let projectURL = context.projectURL,
              TraeProjectLauncher.isInstalled else { return [] }
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(OpenTraeButton(projectURL: projectURL)))]
    }

    @MainActor
    public static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        Self.pluginIntroductionCard(
            footnote: TraeProjectLauncher.isInstalled ? nil : "Trae is not installed on this Mac."
        )
    }
}

public enum OpenTraePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
