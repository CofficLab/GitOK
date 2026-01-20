import MagicKit
import OSLog
import SwiftUI

/// GitPush 插件：在工具栏提供“推送”按钮
class GitPushPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 插件的唯一标识符，用于设置管理
    static var id: String = "GitPush"

    /// 插件显示名称
    static var displayName: String = "GitPush"

    /// 插件描述
    static var description: String = "Git 推送操作"

    /// 插件图标名称（用于设置页展示）
    static var iconName: String = "arrow.up"

    /// 插件是否可配置（在设置中显示启用/禁用开关）
    static var isConfigurable: Bool = true

    /// 日志标识符
    nonisolated static let emoji = "⬆️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    /// 插件标签（用于实例化标识）
    static var label: String = "GitPush"

    static let shared = GitPushPlugin()
    private init() {}

    /// 在工具栏右侧添加视图
    /// - Returns: 推送按钮视图
    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnGitPushView.shared)
    }
}

// MARK: - PluginRegistrant

extension GitPushPlugin {
    /// 自动注册插件到插件注册表
    @objc static func register() {

        Task {
            // 设置排序为 19，位于 Sync(20) 与 Pull(21) 之前
            await PluginRegistry.shared.register(id: Self.id, order: 19) {
                GitPushPlugin.shared
            }
        }
    }
}

// MARK: - Preview

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
