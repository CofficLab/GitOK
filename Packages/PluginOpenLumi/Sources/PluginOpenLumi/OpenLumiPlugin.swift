import Foundation
import KernelCore
import KitOpenIn

/// OpenLumiPlugin — open the current project folder in Lumi.
///
/// 始终启用（`.alwaysOn`），用户不可禁用。
@MainActor
public final class OpenLumiPlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .alwaysOn }

    public init() {
        super.init(target: .lumi)
    }
}
