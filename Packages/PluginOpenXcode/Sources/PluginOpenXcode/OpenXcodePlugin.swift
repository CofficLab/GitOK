import Foundation
import KitOpenIn

/// OpenXcodePlugin — open the current project folder in Xcode.
@MainActor
public final class OpenXcodePlugin: OpenInPluginBase {
    public init() {
        super.init(target: .xcode)
    }
}
