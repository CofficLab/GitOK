import MagicCore
import OSLog
import SwiftUI

class OpenRemotePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenRemotePlugin()
    static let emoji = "🌐"
    static var label: String = "OpenRemote"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenRemoteView.shared)
    }
}

// MARK: - PluginRegistrant
extension OpenRemotePlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "OpenRemote", order: 16) {
                OpenRemotePlugin.shared
            }
        }
    }
}
