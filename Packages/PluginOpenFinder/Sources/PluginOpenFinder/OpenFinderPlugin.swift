import Foundation
import KernelCore
import KitOpenIn

/// OpenFinderPlugin — open the current project folder in Finder.
///
/// 定义自己的加载策略：始终启用（`.alwaysOn`），用户不可禁用。
@MainActor
public final class OpenFinderPlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .alwaysOn }

    public init() {
        super.init(target: .finder)
    }
}
