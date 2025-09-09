import MagicCore
import OSLog
import SwiftUI

class SyncPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = SyncPlugin()
    let emoji = "🔄"
    static var label: String = "Sync"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnSyncView.shared)
    }
}

// MARK: - PluginRegistrant
extension SyncPlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "Sync", order: 20) {
                SyncPlugin.shared
            }
        }
    }
}
