import MagicCore
import OSLog
import SwiftUI

class OpenFinderPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenFinderPlugin()
    let emoji = "📂"
    static var label: String = "OpenFinder"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenFinderView.shared)
    }
}

// MARK: - PluginRegistrant
extension OpenFinderPlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "OpenFinder", order: 14) {
                OpenFinderPlugin.shared
            }
        }
    }
}
