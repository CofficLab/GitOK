import MagicCore
import OSLog
import SwiftUI

class IconPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = IconPlugin()
    let emoji = "📣"
    static var label: String = "Icon"
    var isTab: Bool = true
    
    private init() {}

    func addDetailView() -> AnyView? {
        AnyView(IconDetailLayout.shared)
    }
}

// MARK: - PluginRegistrant
extension IconPlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "Icon", order: 2) {
                IconPlugin.shared
            }
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 800)
    .frame(height: 1200)
}
