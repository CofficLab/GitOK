import MagicKit
import OSLog
import SwiftUI

/// Gitignore 插件：在状态栏提供 .gitignore 查看入口。
class GitignorePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = GitignorePlugin()
    /// 日志标识符
    nonisolated static let emoji = "📄"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "Gitignore"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "Gitignore"

    /// 插件显示名称
    static var displayName: String = "Gitignore"

    /// 插件描述
    static var description: String = "在状态栏提供 .gitignore 查看入口"

    /// 插件图标名称
    static var iconName: String = "doc.badge.gearshape"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        return AnyView(GitignoreStatusIcon.shared)
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
