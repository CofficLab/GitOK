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
        CommandMenu(String(localized: "Configuration")) {
            Button(String(localized: "Repository Settings...")) {
                RootContainer.shared.navigationService.openRepositorySettings()
            }

            Button(String(localized: "Commit Style...")) {
                RootContainer.shared.navigationService.openCommitStyleSettings()
            }

            Divider()

            Button(String(localized: "Plugin Management...")) {
                RootContainer.shared.navigationService.openPluginSettings()
            }
        }
        #endif
    }
}
