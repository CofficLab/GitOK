import MagicKit
import OSLog
import SwiftUI

class ProjectPickerPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "📁"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

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
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register ProjectPickerPlugin")
            }

            await PluginRegistry.shared.register(id: "ProjectPicker", order: 24) {
                ProjectPickerPlugin.shared
            }
        }
    }
}
