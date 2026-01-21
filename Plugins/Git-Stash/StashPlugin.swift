import MagicKit
import OSLog
import SwiftUI

/// Stash 插件：提供stash暂存功能，包括保存、查看、应用和删除stash
class StashPlugin: NSObject, SuperPlugin {

    /// 插件显示名称
    static var displayName: String = "Stash"

    /// 插件描述
    static var description: String = "Git 暂存管理"

    /// 插件图标名称
    static var iconName: String = "archivebox"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = false


    @objc static let shared = StashPlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = true // TODO: 需要正确配置 LibGit2Swift 包依赖


    private override init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(StashList.shared)
    }

    func addStatusBarLeadingView() -> AnyView? {
        return AnyView(StashStatusTile())
    }
}


#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab("Stash")
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab("Stash")
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}