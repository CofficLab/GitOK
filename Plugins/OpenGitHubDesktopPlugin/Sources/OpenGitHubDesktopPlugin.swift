import Foundation
import GitOKCoreKit
import SwiftUI

public enum OpenGitHubDesktopPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OpenGitHubDesktop",
        displayName: OpenGitHubDesktopPluginLocalization.string("Open GitHub Desktop"),
        description: OpenGitHubDesktopPluginLocalization.string("Open the current project folder in GitHub Desktop."),
        iconName: "desktopcomputer",
        order: 8403,
        policy: .optIn,
        tableName: OpenGitHubDesktopPluginLocalization.table
    )


    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        guard let projectURL = context.projectURL,
              GitHubDesktopProjectLauncher.isInstalled else { return [] }
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(OpenGitHubDesktopButton(projectURL: projectURL)))]
    }

    @MainActor
    public static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        Self.pluginIntroductionCard(
            footnote: GitHubDesktopProjectLauncher.isInstalled ? nil : "GitHub Desktop is not installed on this Mac."
        )
    }
}

public enum OpenGitHubDesktopPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
