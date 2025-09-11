import MagicCore
import OSLog
import SwiftUI

class OpenTerminalPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenTerminalPlugin()
    let emoji = "⌨️"
    static var label: String = "OpenTerminal"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenTerminalView())
    }
}

// MARK: - PluginRegistrant
extension OpenTerminalPlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "OpenTerminal", order: 15) {
                OpenTerminalPlugin.shared
            }
        }
    }
}
