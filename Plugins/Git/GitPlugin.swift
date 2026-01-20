import MagicKit
import OSLog
import SwiftUI

class GitPlugin: NSObject, SuperPlugin, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "🚄"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    @objc static let shared = GitPlugin()
    static var label: String = "Git"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "Git"

    /// 插件注册顺序
    static var order: Int = 0

    /// 插件显示名称
    static var displayName: String = "Git"

    /// 插件描述
    static var description: String = "Git 版本控制管理"

    /// 插件图标名称
    static var iconName: String = "arrow.up.arrow.down"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = false

    var isTab: Bool = true

    private override init() {}

    func addDetailView() -> AnyView? {
        return AnyView(GitDetail.shared)
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
