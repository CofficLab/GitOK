import Foundation
import KitOpenIn

/// OpenRemotePlugin — open the current project's remote repository link in the browser.
@MainActor
public final class OpenRemotePlugin: OpenInPluginBase {
    public init() {
        super.init(target: .remote)
    }
}
