import Foundation
import GitOKCoreKit
import SwiftUI

public enum OpenLumiPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OpenLumi",
        displayName: OpenLumiPluginLocalization.string("Open Lumi"),
        description: OpenLumiPluginLocalization.string("Open the current project folder in Lumi."),
        iconName: "sun.max.fill",
        order: 8399,
        policy: .optIn,
        tableName: OpenLumiPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .openIn }

    @MainActor
    public static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        pluginAboutView(
            kind: .openIn,
            footnote: LumiProjectLauncher.isInstalled ? nil : openInUnavailableFootnote()
        )
    }

    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(OpenLumiButton(projectURL: projectURL)))]
    }
}

public enum OpenLumiPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
