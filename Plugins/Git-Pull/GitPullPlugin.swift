import MagicKit
import OSLog
import SwiftUI

class GitPullPlugin: NSObject, SuperPlugin, SuperLog {
    /// 插件显示名称
    static var displayName: String = "GitPull"

    /// 插件描述
    static var description: String = "Git 拉取操作"

    /// 插件图标名称
    static var iconName: String = "arrow.down"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    ///  插件默认启用状态
    static var defaultEnabled: Bool = true

    ///  插件默认启用状态
    @objc static let shared = GitPullPlugin()

    /// 日志标识符
    nonisolated static let emoji = "⬇️"

    /// 是否启用该插件
    @objc static let enable = false

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    override private init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnGitPullView.shared)
    }
}
