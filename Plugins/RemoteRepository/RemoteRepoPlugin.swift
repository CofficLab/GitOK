import MagicKit
import OSLog
import SwiftUI

/// RemoteRepository 插件：在状态栏提供远程仓库管理入口。
class RemoteRepositoryPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 插件的唯一标识符，用于设置管理
    static var id: String = "RemoteRepository"

    /// 插件显示名称
    static var displayName: String = "RemoteRepository"

    /// 插件描述
    static var description: String = "远程仓库管理"

    /// 插件图标名称
    static var iconName: String = "network"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = false
    /// 日志标识符
    nonisolated static let emoji = "🔗"

    static let shared = RemoteRepositoryPlugin()
    static var label: String = "RemoteRepository"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        // 检查用户是否启用了此插件
        guard PluginSettingsStore.shared.isPluginEnabled("RemoteRepository") else {
            return nil
        }

        return AnyView(BtnRemoteRepositoryView.shared)
    }
}

// MARK: - PluginRegistrant

extension RemoteRepositoryPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register RemoteRepoPlugin")
            }

            await PluginRegistry.shared.register(id: "RemoteRepository", order: 27) {
                RemoteRepositoryPlugin.shared
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
