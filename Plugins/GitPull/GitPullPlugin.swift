import MagicKit
import OSLog
import SwiftUI

class GitPullPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = GitPullPlugin()
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "⬇️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "GitPull"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnGitPullView.shared)
    }
}

// MARK: - PluginRegistrant

extension GitPullPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register GitPullPlugin")
            }

            await PluginRegistry.shared.register(id: "GitPull", order: 21) {
                GitPullPlugin.shared
            }
        }
    }
}
