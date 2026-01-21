import MagicKit
import OSLog
import SwiftUI

/// GitPush 插件：在工具栏提供“推送”按钮
class GitPushPlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "GitPush"

    /// 插件描述
    static var description: String = "Git 推送操作"

    /// 插件图标名称（用于设置页展示）
    static var iconName: String = "arrow.up"

    /// 插件是否可配置（在设置中显示启用/禁用开关）
    static var allowUserToggle: Bool = true



    /// 是否启用该插件
    @objc static let shouldRegister = true


    /// 插件标签（用于实例化标识）

    @objc static let shared = GitPushPlugin()
    

    /// 在工具栏右侧添加视图
    /// - Returns: 推送按钮视图
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
