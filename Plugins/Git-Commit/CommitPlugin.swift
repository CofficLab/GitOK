import MagicCore
import OSLog
import SwiftUI

/**
 * Commit插件 - 负责显示和管理Git提交列表
 */
class CommitPlugin: SuperPlugin, SuperLog {
    static let shared = CommitPlugin()
    static let emoji = "🍒"
    static let label: String = "Commit"

    var verbose = false
    
    private init() {}

    /**
     * 添加列表视图 - 显示提交列表
     */
    func addListView(tab: String, project: Project?) -> AnyView? {
        if tab == GitPlugin.label, let project = project, project.isGit {
            if verbose {
                os_log("\(self.t)CommitPlugin addListView")
            }
            return AnyView(CommitList.shared)
        } else {
            if verbose {
                os_log("\(self.t)CommitPlugin addListView nil")
            }
            return nil
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentLayout()
            .hideTabPicker()
    })
    .frame(width: 800, height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
