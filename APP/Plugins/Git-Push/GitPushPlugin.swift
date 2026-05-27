import MagicKit
import OSLog
import SwiftUI

/// GitPush 插件：在工具栏提供 Desktop 风格的同步按钮
class GitPushPlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "Git Sync"

    /// 插件描述
    static var description: String = "根据分支状态执行 Fetch、Pull 或 Push"

    /// 插件图标名称（用于设置页展示）
    static var iconName: String = "arrow.triangle.2.circlepath"

    /// 插件是否可配置（在设置中显示启用/禁用开关）
    static var allowUserToggle: Bool = true
    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    /// 是否启用该插件
    @objc static let shouldRegister = true

    @objc static let shared = GitPushPlugin()

    /// 在工具栏右侧添加视图
    /// - Returns: 同步按钮视图
    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnGitPushView.shared)
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
