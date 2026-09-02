import Foundation
import KitOpenIn

/// OpenFinderPlugin — open the current project folder in Finder.
@MainActor
public final class OpenFinderPlugin: OpenInPluginBase {
    public init() {
        super.init(target: .finder)
    }
}
