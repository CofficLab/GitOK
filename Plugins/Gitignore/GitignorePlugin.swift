import MagicCore
import SwiftUI

/// Gitignore 插件：在状态栏提供 .gitignore 查看入口。
class GitignorePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = GitignorePlugin()
    let emoji = "📄"
    static var label: String = "Gitignore"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(GitignoreStatusIcon.shared)
    }
}

// MARK: - PluginRegistrant
extension GitignorePlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "Gitignore", order: 29) {
                GitignorePlugin.shared
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

