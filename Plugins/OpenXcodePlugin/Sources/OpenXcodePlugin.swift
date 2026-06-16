import Foundation
import GitOKCoreKit
import SwiftUI

public enum OpenXcodePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OpenXcode",
        displayName: OpenXcodePluginLocalization.string("Open Xcode"),
        description: OpenXcodePluginLocalization.string("Open the current project folder in Xcode."),
        iconName: "hammer",
        order: 8402,
        policy: .optIn,
        tableName: OpenXcodePluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .openIn }

    @MainActor
    public static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        pluginAboutView(
            kind: .openIn,
            footnote: XcodeProjectLauncher.isInstalled ? nil : openInUnavailableFootnote()
        )
    }


    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(OpenXcodeButton(projectURL: projectURL)))]
    }
}

public enum OpenXcodePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
