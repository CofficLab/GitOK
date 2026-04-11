import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// Clean Status Plugin
/// 监听项目变化，自动更新项目的 clean 状态到 ProjectVM
class CleanStatusPlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "Clean Status"

    /// 插件描述
    static var description: String = String(localized: "跟踪项目是否 clean（无未提交的更改）", table: "CleanStatus")

    /// 插件图标名称
    static var iconName: String = "checkmark.circle"

    /// 插件是否可配置
    static var allowUserToggle = false

    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    /// 插件注册顺序
    static var order: Int = 24

    /// 是否启用该插件
    @objc static let shouldRegister = true

    /// 单例实例
    @objc static var shared = CleanStatusPlugin()

    override init() {
        super.init()
    }

    /// 添加根视图包裹
    /// 监听项目变化，自动更新项目的 clean 状态到 ProjectVM
    func addRootView<Content>(@ViewBuilder content: () -> Content) -> AnyView? where Content: View {
        return AnyView(
            CleanStatusRootView {
                content()
            }
        )
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