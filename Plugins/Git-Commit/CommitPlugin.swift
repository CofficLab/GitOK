import MagicCore
import OSLog
import SwiftUI

/**
 * Commit插件 - 负责显示和管理Git提交列表
 */
class CommitPlugin: SuperPlugin, SuperLog {
    let emoji = "🍒"
    var label: String = "Commit"
    var isTab: Bool = true

    /**
     * 添加列表视图 - 显示提交列表
     */
    func addListView(tab: String, project: Project?) -> AnyView? {
        if tab == GitPlugin().label, let project = project, project.isGit {
            AnyView(CommitList().environmentObject(GitProvider.shared))
        } else {
            nil
        }
    }

}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 800, height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
