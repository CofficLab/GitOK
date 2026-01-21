import Cocoa
import MagicKit
import OSLog
import SwiftUI

/// 打开 GitHub Desktop 插件
/// 在工具栏中提供用 GitHub Desktop 打开当前项目的功能
class OpenGitHubDesktopPlugin: NSObject, SuperPlugin {
    @objc static let shared = OpenGitHubDesktopPlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = false


    /// 插件显示名称
    static var displayName: String = "OpenGitHubDesktop"

    /// 插件描述
    static var description: String = "在 GitHub Desktop 中打开当前项目"

    /// 插件图标名称（用于设置页展示）
    static var iconName: String = "desktopcomputer"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = true


    override private init() {}

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
