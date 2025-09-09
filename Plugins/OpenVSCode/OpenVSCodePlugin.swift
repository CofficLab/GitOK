import MagicCore
import OSLog
import SwiftUI

class OpenVSCodePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenVSCodePlugin()
    let emoji = "💻"
    static var label: String = "OpenVSCode"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenVSCodeView.shared)
    }
}

// MARK: - PluginRegistrant
extension OpenVSCodePlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "OpenVSCode", order: 12) {
                OpenVSCodePlugin.shared
            }
        }
    }
}
