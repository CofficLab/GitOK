import Foundation
import KernelCore
import KitOpenIn

/// OpenKiroPlugin — open the current project folder in Kiro.
///
/// 始终启用（`.alwaysOn`），用户不可禁用。
@MainActor
public final class OpenKiroPlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .alwaysOn }

    public init() {
        super.init(target: .kiro)
    }
}
