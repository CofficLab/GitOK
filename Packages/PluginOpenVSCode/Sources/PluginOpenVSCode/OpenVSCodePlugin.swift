import Foundation
import KitOpenIn

/// OpenVSCodePlugin — open the current project folder in Visual Studio Code.
@MainActor
public final class OpenVSCodePlugin: OpenInPluginBase {
    public init() {
        super.init(target: .vscode)
    }
}
