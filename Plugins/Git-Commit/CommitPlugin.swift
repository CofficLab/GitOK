import MagicKit
import OSLog
import SwiftUI

/**
 * Commit插件 - 负责显示和管理Git提交列表
 */
class CommitPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    nonisolated static let emoji = "🍒"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static let shared = CommitPlugin()
    static let label: String = "Commit"
    
    private init() {}

    /**
     * 添加列表视图 - 显示提交列表
     */
    func addListView(tab: String, project: Project?) -> AnyView? {
        if tab == GitPlugin.label, project != nil {
            if Self.verbose {
                os_log("\(self.t)🔄 CommitPlugin enabled addListView: \(tab)")
            }
            return AnyView(CommitList.shared)
        }

        if Self.verbose {
            os_log("\(self.t)🔄 CommitPlugin disabled addListView: \(tab)")
        }
        
        return nil
    }
}

// MARK: - PluginRegistrant
extension CommitPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register CommitPlugin")
            }

            await PluginRegistry.shared.register(id: "Commit", order: 23) {
                CommitPlugin.shared
            }
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentLayout()
            .hideTabPicker()
    })
    .frame(width: 800, height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
