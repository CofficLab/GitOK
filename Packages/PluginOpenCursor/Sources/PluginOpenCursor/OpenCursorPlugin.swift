import Foundation
import KernelCore
import KitOpenIn

/// OpenCursorPlugin — open the current project folder in Cursor.
///
/// 始终启用（`.alwaysOn`），用户不可禁用。
@MainActor
public final class OpenCursorPlugin: OpenInPluginBase {
    public override var pluginPolicy: PluginEnablePolicy { .alwaysOn }

    public init() {
        super.init(target: .cursor)
    }
}
