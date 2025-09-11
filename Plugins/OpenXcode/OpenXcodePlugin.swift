import MagicCore
import OSLog
import SwiftUI

class OpenXcodePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenXcodePlugin()
    let emoji = "🛠️"
    static var label: String = "OpenXcode"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenXcodeView.shared)
    }
}

// MARK: - PluginRegistrant
extension OpenXcodePlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "OpenXcode", order: 11) {
                OpenXcodePlugin.shared
            }
        }
    }
}
