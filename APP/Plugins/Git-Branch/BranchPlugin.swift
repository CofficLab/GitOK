import MagicKit
import OSLog
import SwiftUI

/// Branch 插件：提供分支列表视图（工具栏右侧）并在状态栏左侧展示当前分支。
class BranchPlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "Branch"

    /// 插件描述
    static var description: String = String(localized: "Git 分支管理", table: "GitBranch")

    /// 插件图标名称
    static var iconName: String = "arrow.triangle.branch"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle = true
    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    @objc static let shared = BranchPlugin()

    /// 插件注册顺序
    static var order: Int = 22

    /// 是否启用该插件
    @objc static let shouldRegister = true

    

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BranchesView.shared)
    }

    func addStatusBarLeadingView() -> AnyView? {
        return AnyView(BranchStatusTile())
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab("Branch")
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab("Branch")
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
