import Foundation
import KernelCore
import KitOpenIn

/// OpenAntigravityPlugin — open the current project folder in Antigravity.
///
/// 始终启用（`.alwaysOn`），用户不可禁用。
@MainActor
public final class OpenAntigravityPlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .alwaysOn }

    public init() {
        super.init(target: .antigravity)
    }
}
