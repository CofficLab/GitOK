import MagicCore
import OSLog
import SwiftUI

class BranchPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    let emoji = "🌿"
    static let shared = BranchPlugin()
    static var label: String = "Branch"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BranchesView.shared)
    }
}

// MARK: - PluginRegistrant
extension BranchPlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "Branch", order: 22) {
                BranchPlugin.shared
            }
        }
    }
}
