import MagicCore
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
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
