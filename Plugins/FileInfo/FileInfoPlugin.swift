import MagicKit
import OSLog
import SwiftUI

/// SmartFile 插件：在状态栏左侧展示当前文件信息的 Tile。
class SmartFilePlugin: NSObject, SuperPlugin {
    /// 是否启用该插件
    @objc static let shouldRegister = true

    @objc static let shared = SmartFilePlugin()

    /// 插件显示名称
    static var displayName: String = "FileInfo"

    /// 插件描述
    static var description: String = "在状态栏左侧展示当前文件信息"

    /// 插件图标名称
    static var iconName: String = .iconDocument

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle = true
    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    func addStatusBarLeadingView() -> AnyView? {
        AnyView(TileFile.shared)
    }
}

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
