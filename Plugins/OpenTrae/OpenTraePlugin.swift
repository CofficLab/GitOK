import MagicCore
import OSLog
import SwiftUI

class OpenTraePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenTraePlugin()
    let emoji = "🤖"
    static var label: String = "OpenTrae"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenTraeView.shared)
    }
}

// MARK: - PluginRegistrant
extension OpenTraePlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "OpenTrae", order: 13) {
                OpenTraePlugin.shared
            }
        }
    }
}
