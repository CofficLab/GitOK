import MagicKit
import SwiftUI
import OSLog

/// Gitignore 插件：在状态栏提供 .gitignore 查看入口。
class GitignorePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = GitignorePlugin()
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "📄"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    static var label: String = "Gitignore"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(GitignoreStatusIcon.shared)
    }
}

// MARK: - PluginRegistrant
extension GitignorePlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register GitignorePlugin")
            }

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

