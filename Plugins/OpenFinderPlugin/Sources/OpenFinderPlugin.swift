import Foundation
import GitOKCoreKit
import SwiftUI

public enum OpenFinderPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OpenFinder",
        displayName: OpenFinderPluginLocalization.string("Open Finder"),
        description: OpenFinderPluginLocalization.string("Open the current project folder in Finder."),
        iconName: "folder",
        order: 8300,
        policy: .optIn,
        tableName: OpenFinderPluginLocalization.table
    )


    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(OpenFinderButton(projectURL: projectURL)))]
    }

    @MainActor
    public static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        Self.pluginIntroductionCard()
    }
}

public enum OpenFinderPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
