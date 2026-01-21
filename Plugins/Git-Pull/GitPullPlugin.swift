import MagicKit
import OSLog
import SwiftUI

class GitPullPlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "GitPull"

    /// 插件描述
    static var description: String = "Git 拉取操作"

    /// 插件图标名称
    static var iconName: String = "arrow.down"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = true
    
    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    @objc static let shared = GitPullPlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = true

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnGitPullView.shared)
    }
}
