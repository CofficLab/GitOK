import Cocoa
import MagicKit
import OSLog
import SwiftUI

/// 打开 GitHub Desktop 插件
/// 在工具栏中提供用 GitHub Desktop 打开当前项目的功能
class OpenGitHubDesktopPlugin: SuperPlugin, SuperLog {
    static let shared = OpenGitHubDesktopPlugin()
    /// 日志标识符
    nonisolated static let emoji = "🐱"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenGitHubDesktop"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "OpenGitHubDesktop"

    /// 插件显示名称
    static var displayName: String = "OpenGitHubDesktop"

    /// 插件描述
    static var description: String = "在 GitHub Desktop 中打开当前项目"

    /// 插件图标名称（用于设置页展示）
    static var iconName: String = "desktopcomputer"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    private init() {}

    /// 在工具栏右侧添加视图
    /// - Returns: 打开 GitHub Desktop 的按钮视图
    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenGitHubDesktopView.shared)
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
