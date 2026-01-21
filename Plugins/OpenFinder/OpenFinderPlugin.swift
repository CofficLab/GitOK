import MagicKit
import OSLog
import SwiftUI

/// 打开 Finder 插件
/// 提供在工具栏中打开当前项目目录的 Finder 的功能
class OpenFinderPlugin: NSObject, SuperPlugin {
    @objc static let shared = OpenFinderPlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = true

    /// 插件显示名称
    static var displayName: String = "OpenFinder"

    /// 插件描述
    static var description: String = "在 Finder 中打开当前项目目录"

    /// 插件图标名称
    static var iconName: String = "folder"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle = true

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenFinderView.shared)
    }
}
