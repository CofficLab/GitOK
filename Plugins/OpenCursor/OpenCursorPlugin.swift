import Cocoa
import MagicKit
import OSLog
import SwiftUI

class OpenCursorPlugin: NSObject, SuperPlugin, SuperLog {
    @objc static let shared = OpenCursorPlugin()
    /// 日志标识符
    nonisolated static let emoji = "🖱️"

    /// 是否启用该插件
    @objc static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenCursor"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "OpenCursor"

    /// 插件显示名称
    static var displayName: String = "OpenCursor"

    /// 插件描述
    static var description: String = "在 Cursor 中打开当前项目"

    /// 插件图标名称
    static var iconName: String = "cursor.rays"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    private override init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenCursorView.shared)
    }
}

