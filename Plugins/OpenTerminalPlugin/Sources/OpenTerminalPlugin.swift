import Foundation
import GitOKCoreKit
import SwiftUI

public enum OpenTerminalPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OpenTerminal",
        displayName: OpenTerminalPluginLocalization.string("Open Terminal"),
        description: OpenTerminalPluginLocalization.string("Open the current project folder in Terminal."),
        iconName: "terminal",
        order: 8310,
        policy: .optIn,
        tableName: OpenTerminalPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .openIn }

    @MainActor
    public static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        pluginAboutView(
            kind: .openIn,
            footnote: TerminalLauncher.hasInstalledTerminal
                ? nil
                : GitOKPluginAboutLocalization.string("about.openIn.footnote.noTerminal")
        )
    }


    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(OpenTerminalButton(projectURL: projectURL)))]
    }
}

public enum OpenTerminalPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
