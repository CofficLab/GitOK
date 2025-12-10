import MagicCore
import SwiftUI

/// 状态栏分支信息胶囊，显示当前分支或占位提示。
struct BranchStatusTile: View {
    @EnvironmentObject var data: DataProvider

    private var branchText: String {
        if let branch = data.branch {
            return branch.name
        }
        if data.project == nil {
            return "未选择项目"
        }
        return "无分支"
    }

    var body: some View {
        StatusBarTile(icon: "arrow.branch") {
            Text(branchText)
        }
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

