import MagicKit
import SwiftUI

/// Git LFS 插件：在状态栏展示 LFS 配置风险与大文件建议。
class GitLFSPlugin: NSObject, SuperPlugin {
    static var displayName: String = "Git LFS"

    static var description: String = "Git LFS 状态与大文件建议"

    static var iconName: String = "externaldrive.badge.timemachine"

    static var allowUserToggle: Bool = true
    static var defaultEnabled: Bool = true

    @objc static let shared = GitLFSPlugin()

    @objc static let shouldRegister = false

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(GitLFSStatusTile())
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
