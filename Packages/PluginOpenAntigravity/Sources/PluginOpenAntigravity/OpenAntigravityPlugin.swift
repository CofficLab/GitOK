import Foundation
import KitOpenIn

/// OpenAntigravityPlugin — open the current project folder in Antigravity.
@MainActor
public final class OpenAntigravityPlugin: OpenInPluginBase {
    public init() {
        super.init(target: .antigravity)
    }
}
