import SwiftUI
import MagicKit

/// 配置命令：在应用菜单中添加配置相关的功能入口
struct ConfigCommand: Commands, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "⚙️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    var body: some Commands {
        #if os(macOS)
        CommandMenu("配置") {
            Button("仓库设置...") {
                // 发送打开仓库设置的通知
                NotificationCenter.default.post(name: .openRepositorySettings, object: nil)
            }

            Button("Commit 风格...") {
                // 发送打开Commit风格设置的通知
                NotificationCenter.default.post(name: .openCommitStyleSettings, object: nil)
            }

            Divider()

            Button("插件管理...") {
                // 发送打开插件设置的通知
                NotificationCenter.default.post(name: .openPluginSettings, object: nil)
            }
        }
        #endif
    }
}
