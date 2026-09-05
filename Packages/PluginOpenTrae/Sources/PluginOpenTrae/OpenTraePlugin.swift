import Foundation
import KernelCore
import KitOpenIn

/// OpenTraePlugin — open the current project folder in Trae.
///
/// 始终启用（`.alwaysOn`），用户不可禁用。
@MainActor
public final class OpenTraePlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .alwaysOn }

    public init() {
        super.init(target: .trae)
    }
}
