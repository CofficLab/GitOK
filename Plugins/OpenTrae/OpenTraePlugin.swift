import Cocoa
import MagicKit
import OSLog
import SwiftUI

class OpenTraePlugin: NSObject, SuperPlugin, SuperLog {
    @objc static let shared = OpenTraePlugin()
    /// 日志标识符
    nonisolated static let emoji = "🤖"

    /// 是否启用该插件
    @objc static let shouldRegister = false

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    /// 插件显示名称
    static var displayName: String = "OpenTrae"

    /// 插件描述
    static var description: String = "在 Trae 中打开当前项目"

    /// 插件图标名称
    static var iconName: String = "brain"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = true


    override private init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenTraeView.shared)
    }
}
