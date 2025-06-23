import MagicCore
import OSLog
import SwiftUI

class GitPullPlugin: SuperPlugin, SuperLog {
    static let shared = GitPullPlugin()
    let emoji = "⬇️"
    static var label: String = "GitPull"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnGitPullView.shared)
    }
} 