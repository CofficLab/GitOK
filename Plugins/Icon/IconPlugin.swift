import MagicKit
import OSLog
import SwiftUI

class IconPlugin: NSObject, SuperPlugin {

    /// 是否启用该插件
    @objc static let shouldRegister = false


    @objc static let shared = IconPlugin()


    /// 插件显示名称
    static var displayName: String = "Icon Detail"

    /// 插件描述
    static var description: String = "图标详情视图"

    /// 插件图标名称
    static var iconName: String = "photo"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = false


    private override init() {}

    /// 返回 Icon 标签页的详情视图
    func addDetailView(for tab: String) -> AnyView? {
        guard tab == "Icon" else { return nil }
        return AnyView(IconDetailLayout.shared)
    }
}


// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab("Icon")
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab("Icon")
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
