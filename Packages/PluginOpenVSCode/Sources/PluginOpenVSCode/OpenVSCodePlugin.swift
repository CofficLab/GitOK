import Foundation
import KernelCore
import KitOpenIn

/// OpenVSCodePlugin — open the current project folder in Visual Studio Code.
///
/// 始终启用（`.alwaysOn`），用户不可禁用。
@MainActor
public final class OpenVSCodePlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .alwaysOn }

    public init() {
        super.init(target: .vscode)
    }
}
