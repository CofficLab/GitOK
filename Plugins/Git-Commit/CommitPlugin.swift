import MagicKit
import OSLog
import SwiftUI

/**
 * Commit插件 - 负责显示和管理Git提交列表
 */
class CommitPlugin: NSObject, SuperPlugin {

    /// 是否启用该插件
    @objc static let shouldRegister = false


    @objc static let shared = CommitPlugin()
    static let label: String = "Commit"


    /// 插件显示名称
    static var displayName: String = "Commit"

    /// 插件描述
    static var description: String = "Git 提交管理"

    /// 插件图标名称
    static var iconName: String = "arrow.up.arrow.down"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = false

    
    private override init() {}

    /**
     * 添加列表视图 - 显示提交列表
     */
    func addListView(tab: String, project: Project?) -> AnyView? {
        if tab == "Git", let project = project, project.isGitRepo {
            return AnyView(CommitList.shared)
        }

        return nil
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
