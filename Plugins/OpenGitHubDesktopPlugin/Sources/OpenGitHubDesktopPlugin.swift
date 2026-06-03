import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenGitHubDesktopPlugin: GitOKPlugin {
    public static let shared = OpenGitHubDesktopPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenGitHubDesktop",
        displayName: OpenGitHubDesktopPluginLocalization.string("Open GitHub Desktop"),
        description: OpenGitHubDesktopPluginLocalization.string("Open the current project folder in GitHub Desktop."),
        iconName: "desktopcomputer",
        order: 8403,
        policy: .optIn,
        tableName: OpenGitHubDesktopPluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard GitHubDesktopProjectLauncher.isInstalled, let projectURL = context.projectURL else { return nil }
        return AnyView(OpenGitHubDesktopButton(projectURL: projectURL))
    }
}

public enum OpenGitHubDesktopPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
