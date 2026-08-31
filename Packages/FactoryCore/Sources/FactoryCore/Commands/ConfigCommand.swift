import SwiftUI
import KitGitOKCore
import KitGitOKSupport
import KernelCore

/// 配置命令：在应用菜单中添加配置相关的功能入口
public struct ConfigCommand: Commands, SuperLog {
    /// 日志标识符
    public nonisolated static let emoji = "⚙️"

    /// 是否启用详细日志输出
    public nonisolated static let verbose = false

    private let kernel: KernelCoreContainer

    public init(kernel: KernelCoreContainer) {
        self.kernel = kernel
    }

    public var body: some Commands {
        #if os(macOS)
        CommandMenu(String(localized: "Configuration")) {
            Button(String(localized: "Repository Settings...")) {
                kernel.resolveProvider((any GitOKNavigationServicing).self)?.openRepositorySettings()
            }

            Button(String(localized: "Commit Style...")) {
                kernel.resolveProvider((any GitOKNavigationServicing).self)?.openCommitStyleSettings()
            }

            Divider()

            Button(String(localized: "Plugin Management...")) {
                kernel.resolveProvider((any GitOKNavigationServicing).self)?.openPluginSettings()
            }
        }
        #endif
    }
}
