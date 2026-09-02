import Foundation
import KitOpenIn

/// OpenKiroPlugin — open the current project folder in Kiro.
@MainActor
public final class OpenKiroPlugin: OpenInPluginBase {
    public init() {
        super.init(target: .kiro)
    }
}
