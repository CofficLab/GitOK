import MagicKit
import OSLog
import SwiftUI

/// Git 详情视图插件 - 负责提供 Git 标签页的详情视图
class GitDetailPlugin: NSObject, SuperPlugin {
    /// 是否启用该插件
    @objc static let shouldRegister = true

    @objc static let shared = GitDetailPlugin()

    /// 插件注册顺序
    static var order: Int = 0

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = false

    override private init() {}

    /// 返回 Git 标签页的详情视图
    func addDetailView(for tab: String) -> AnyView? {
        guard tab == "Git" else { return nil }
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
