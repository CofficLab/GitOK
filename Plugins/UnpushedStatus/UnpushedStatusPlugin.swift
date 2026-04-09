import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// 未推送提交状态插件
/// 负责跟踪并更新项目的未推送提交数量，在状态栏显示图标
class UnpushedStatusPlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "Unpushed Status"

    /// 插件描述
    static var description: String = String(localized: "显示未推送提交数量", table: "UnpushedStatus")

    /// 插件图标名称
    static var iconName: String = "arrow.up.circle"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle = true

    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    /// 插件注册顺序
    static var order: Int = 25

    /// 是否启用该插件
    @objc static let shouldRegister = true

    /// 是否启用详细日志输出
    private let verbose = false

    /// 单例实例
    static var shared = UnpushedStatusPlugin()

    override init() {
        super.init()
    }

    /// 添加状态栏后置视图（显示在右侧）
    func addStatusBarTrailingView() -> AnyView? {
        return AnyView(UnpushedStatusTile())
    }

    /// 刷新未推送提交状态
    func refresh() {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }

        // 通过 AppDelegate 获取 ProjectVM
        // 由于 ProjectVM 是通过环境对象传递的，我们需要找到一种方式来更新它
        // 这里我们使用 NotificationCenter 来通知刷新

        if verbose {
            os_log("\(Self.t)🔄 Refreshing unpushed status")
        }

        NotificationCenter.default.post(name: .refreshUnpushedStatus, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let refreshUnpushedStatus = Notification.Name("refreshUnpushedStatus")
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