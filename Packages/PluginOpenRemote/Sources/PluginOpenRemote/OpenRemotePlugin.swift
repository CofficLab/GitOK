import Foundation
import KernelCore
import KitOpenIn

/// OpenRemotePlugin — open the current project's remote repository link in the browser.
///
/// 始终启用（`.alwaysOn`），用户不可禁用。
@MainActor
public final class OpenRemotePlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .alwaysOn }

    public init() {
        super.init(target: .remote)
    }
}
