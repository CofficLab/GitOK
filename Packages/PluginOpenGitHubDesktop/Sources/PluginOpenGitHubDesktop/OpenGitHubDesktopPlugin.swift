import Foundation
import GitOKPluginKit
import SwiftUI

public struct OpenGitHubDesktopPlugin: GitOKPackagedPlugin {
    public static let shared = OpenGitHubDesktopPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenGitHubDesktop",
        displayName: PluginOpenGitHubDesktopLocalization.string("Open GitHub Desktop"),
        description: PluginOpenGitHubDesktopLocalization.string("Open the current project folder in GitHub Desktop."),
        iconName: "desktopcomputer",
        order: 8403,
        allowUserToggle: true,
        defaultEnabled: false,
        tableName: PluginOpenGitHubDesktopLocalization.table
    )

    private init() {}

    public func toolBarTrailingView() -> AnyView? {
        AnyView(OpenGitHubDesktopButton())
    }
}

public enum PluginOpenGitHubDesktopLocalization {
    public static let table = "OpenGitHubDesktop"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
