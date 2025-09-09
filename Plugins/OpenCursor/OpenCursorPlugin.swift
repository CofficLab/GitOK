import SwiftUI
import MagicCore
import OSLog

class OpenCursorPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenCursorPlugin()
    let emoji = "🖱️"
    static var label: String = "OpenCursor"

    
    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenCursorView.shared)
    }
}

// MARK: - PluginRegistrant
extension OpenCursorPlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "OpenCursor", order: 10) {
                OpenCursorPlugin.shared
            }
        }
    }
}
