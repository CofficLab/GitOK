import Foundation
import KernelCore
import KitOpenIn

/// OpenGitHubDesktopPlugin — open the current project folder in GitHub Desktop.
///
/// 始终启用（`.alwaysOn`），用户不可禁用。
@MainActor
public final class OpenGitHubDesktopPlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .alwaysOn }

    public init() {
        super.init(target: .githubDesktop)
    }
}
