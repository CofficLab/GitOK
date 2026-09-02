import Foundation
import KitOpenIn

/// OpenCursorPlugin — open the current project folder in Cursor.
@MainActor
public final class OpenCursorPlugin: OpenInPluginBase {
    public init() {
        super.init(target: .cursor)
    }
}
