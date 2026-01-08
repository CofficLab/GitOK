import MagicKit
import OSLog
import SwiftData
import SwiftUI

/// 非 Git 项目提示视图
/// 当当前目录不是 Git 仓库时显示此视图
struct NotGit: View, SuperThread, SuperEvent {
    var body: some View {
        GuideView(
            systemImage: "exclamationmark.triangle",
            title: NSLocalizedString("not_git_project", bundle: .main, comment: "")
        )
    }
}

#Preview {
    RootView {
        NotGit()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
