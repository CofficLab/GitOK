import Foundation
import KitGitOKCore
import SwiftUI

public enum OpenFinderPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OpenFinder",
        displayName: OpenFinderPluginLocalization.string("Open Finder"),
        description: OpenFinderPluginLocalization.string("Open the current project folder in Finder."),
        iconName: "folder",
        order: 400,
        policy: .optIn,
        tableName: OpenFinderPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .openIn }


    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKToolbarItem(id: metadata.id, title: "Reveal in Finder", order: 180, view: AnyView(OpenFinderButton(projectURL: projectURL)))]
    }
}

public enum OpenFinderPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
