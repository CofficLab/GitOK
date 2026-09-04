import Foundation
import KernelCore
import KitOpenIn

/// OpenFinderPlugin — open the current project folder in Finder.
///
/// 定义自己的加载策略：始终加载（`.required`），不受全局禁用策略影响。
@MainActor
public final class OpenFinderPlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .required }

    public init() {
        super.init(target: .finder)
    }
}
