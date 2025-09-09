import MagicCore
import OSLog
import SwiftUI

class GitPullPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = GitPullPlugin()
    let emoji = "⬇️"
    static var label: String = "GitPull"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnGitPullView.shared)
    }
} 
// MARK: - PluginRegistrant
extension GitPullPlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "GitPull", order: 21) {
                GitPullPlugin.shared
            }
        }
    }
}
