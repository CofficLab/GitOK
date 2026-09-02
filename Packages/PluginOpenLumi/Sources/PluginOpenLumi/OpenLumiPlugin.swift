import Foundation
import KitOpenIn

/// OpenLumiPlugin — open the current project folder in Lumi.
@MainActor
public final class OpenLumiPlugin: OpenInPluginBase {
    public init() {
        super.init(target: .lumi)
    }
}
