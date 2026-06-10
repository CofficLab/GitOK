import SwiftUI
import GitOKSupportKit

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
                RootContainer.shared.navigationService.openRepositorySettings()
            }

            Button("Commit 风格...") {
                RootContainer.shared.navigationService.openCommitStyleSettings()
            }

            Divider()

            Button("插件管理...") {
                RootContainer.shared.navigationService.openPluginSettings()
            }
        }
        #endif
    }
}
