import MagicKit
import OSLog
import SwiftUI

class ProjectPickerPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    let emoji = "📁"
    static var label: String = "ProjectPicker"

    static let shared = ProjectPickerPlugin()

    private init() {
    }

    func addToolBarLeadingView() -> AnyView? {
        AnyView(ProjectPickerView.shared)
    }
}

// MARK: - Previews

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

// MARK: - PluginRegistrant
extension ProjectPickerPlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "ProjectPicker", order: 24) {
                ProjectPickerPlugin.shared
            }
        }
    }
}
