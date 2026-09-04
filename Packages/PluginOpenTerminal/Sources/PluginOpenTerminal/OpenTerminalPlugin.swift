import Foundation
import KernelCore
import KitOpenIn

/// OpenTerminalPlugin — open the current project folder in Terminal.
///
/// 始终启用（`.alwaysOn`），用户不可禁用。
@MainActor
public final class OpenTerminalPlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .alwaysOn }

    public init() {
        super.init(target: .terminal)
    }
}
