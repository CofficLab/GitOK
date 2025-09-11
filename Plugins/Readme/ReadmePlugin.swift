import MagicCore
import OSLog
import SwiftUI

class ReadmePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = ReadmePlugin()
    let emoji = "📖"
    static var label: String = "Readme"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(ReadmeStatusIcon.shared)
    }
} 
// MARK: - PluginRegistrant
extension ReadmePlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "Readme", order: 28) {
                ReadmePlugin.shared
            }
        }
    }
}
