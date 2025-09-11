import MagicCore
import OSLog
import SwiftUI

class RemoteRepositoryPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = RemoteRepositoryPlugin()
    static let emoji = "🔗"
    static var label: String = "RemoteRepository"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(BtnRemoteRepositoryView.shared)
    }
} 

// MARK: - PluginRegistrant
extension RemoteRepositoryPlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "RemoteRepository", order: 27) {
                RemoteRepositoryPlugin.shared
            }
        }
    }
}
