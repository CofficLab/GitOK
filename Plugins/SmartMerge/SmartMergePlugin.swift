import MagicCore
import OSLog
import SwiftUI

class SmartMergePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = SmartMergePlugin()
    let emoji = "📣"
    static var label: String = "SmartMerge"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(TileMerge.shared)
    }
}

// MARK: - PluginRegistrant
extension SmartMergePlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "SmartMerge", order: 25) {
                SmartMergePlugin.shared
            }
        }
    }
}
