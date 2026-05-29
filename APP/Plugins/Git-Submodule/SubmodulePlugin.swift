import MagicKit
import SwiftUI

/// Submodule 插件：在状态栏展示子模块状态，并提供初始化、更新与 diff 摘要入口。
class SubmodulePlugin: NSObject, SuperPlugin {
    static var displayName: String = "Submodule"

    static var description: String = "Git 子模块状态与更新"

    static var iconName: String = "shippingbox"

    static var allowUserToggle: Bool = true
    static var defaultEnabled: Bool = true

    @objc static let shared = SubmodulePlugin()

    @objc static let shouldRegister = false

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(SubmoduleStatusTile())
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
