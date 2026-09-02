import Foundation
import KitOpenIn

/// OpenTerminalPlugin — open the current project folder in Terminal.
@MainActor
public final class OpenTerminalPlugin: OpenInPluginBase {
    public init() {
        super.init(target: .terminal)
    }
}
