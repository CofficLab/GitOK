import Foundation
import KitOpenIn

/// OpenGitHubDesktopPlugin — open the current project folder in GitHub Desktop.
@MainActor
public final class OpenGitHubDesktopPlugin: OpenInPluginBase {
    public init() {
        super.init(target: .githubDesktop)
    }
}
