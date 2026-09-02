import Foundation
import KitOpenIn

/// OpenTraePlugin — open the current project folder in Trae.
@MainActor
public final class OpenTraePlugin: OpenInPluginBase {
    public init() {
        super.init(target: .trae)
    }
}
