import MagicKit
import OSLog
import SwiftUI

class GitPullPlugin: NSObject, SuperPlugin, SuperLog {
    /// 插件的唯一标识符，用于设置管理
    static var id: String = "GitPull"

    /// 插件显示名称
    static var displayName: String = "GitPull"

    /// 插件描述
    static var description: String = "Git 拉取操作"

    /// 插件图标名称
    static var iconName: String = "arrow.down"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true
    @objc static let shared = GitPullPlugin()
    /// 日志标识符
    nonisolated static let emoji = "⬇️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "GitPull"

    private override init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnGitPullView.shared)
    }
}

