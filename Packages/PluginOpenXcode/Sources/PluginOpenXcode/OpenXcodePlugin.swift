import Foundation
import KernelCore
import KitOpenIn

/// OpenXcodePlugin — open the current project folder in Xcode.
///
/// 始终启用（`.alwaysOn`），用户不可禁用。
@MainActor
public final class OpenXcodePlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .alwaysOn }

    public init() {
        super.init(target: .xcode)
    }
}
