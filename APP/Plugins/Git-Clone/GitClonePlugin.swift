import MagicKit
import OSLog
import SwiftUI

class GitClonePlugin: NSObject, SuperPlugin {
    static var displayName: String = "GitClone"

    static var description: String = "Git 克隆远程仓库到本地"

    static var iconName: String = "square.and.arrow.down"

    static var allowUserToggle: Bool = true

    static var defaultEnabled: Bool = true

    @objc static let shared = GitClonePlugin()

    @objc static let shouldRegister = true

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnGitCloneView.shared)
    }
}
