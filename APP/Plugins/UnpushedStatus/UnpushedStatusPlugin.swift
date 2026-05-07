import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// 未推送提交状态插件
/// 通过根视图包裹来跟踪并更新项目的未推送提交数量
class UnpushedStatusPlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "Unpushed Status"

    /// 插件描述
    static var description: String = String(localized: "显示未推送提交数量", table: "UnpushedStatus")

    /// 插件图标名称
    static var iconName: String = "arrow.up.circle"

    /// 插件是否可配置
    static var allowUserToggle = false

    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    /// 插件注册顺序
    static var order: Int = 25

    /// 是否启用该插件
    @objc static let shouldRegister = true

    /// 是否启用详细日志输出
    private let verbose = true

    /// 单例实例
    @objc static var shared = UnpushedStatusPlugin()

    override init() {
        super.init()
    }

    /// 添加根视图包裹
    /// 监听项目变化，自动更新未推送提交数量到 ProjectVM
    func addRootView<Content>(@ViewBuilder content: () -> Content) -> AnyView? where Content: View {
        return AnyView(
            UnpushedStatusRootView(content: content())
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
