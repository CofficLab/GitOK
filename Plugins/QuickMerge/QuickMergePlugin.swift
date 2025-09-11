import MagicCore
import OSLog
import SwiftUI

class QuickMergePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    let emoji = "📣"
    static var label: String = "QuickMerge"

    static let shared = QuickMergePlugin()

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(TileQuickMerge.shared)
    }
}

#Preview("APP") {
    RootView(content: {
        ContentLayout()
            .hideSidebar()
            .hideToolbar()
    })
    .frame(width: 800, height: 600)
}

#Preview("Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

// MARK: - PluginRegistrant
extension QuickMergePlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "QuickMerge", order: 30) {
                QuickMergePlugin.shared
            }
        }
    }
}
