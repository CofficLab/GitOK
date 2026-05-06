import Cocoa
import MagicKit
import OSLog
import SwiftUI

class OpenCursorPlugin: NSObject, SuperPlugin {
    @objc static let shared = OpenCursorPlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = true

    /// 插件显示名称
    static var displayName: String = "OpenCursor"

    /// 插件描述
    static var description: String = "在 Cursor 中打开当前项目"

    /// 插件图标名称
    static var iconName: String = "cursor.rays"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle = true

    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenCursorView.shared)
    }
}
