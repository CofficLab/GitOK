import MagicCore
import OSLog
import SwiftUI

class SmartProjectPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = SmartProjectPlugin()
    let emoji = "📣"
    static var label: String = "SmartProject"

    private init() {}
    
    func addStatusBarLeadingView() -> AnyView? {
        AnyView(TileProject.shared)
    }
}

// MARK: - PluginRegistrant
extension SmartProjectPlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "SmartProject", order: 29) {
                SmartProjectPlugin.shared
            }
        }
    }
}
