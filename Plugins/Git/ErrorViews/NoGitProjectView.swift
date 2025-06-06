import SwiftUI

/// 非Git项目提示视图
/// 当选择的项目不是Git项目时显示此视图
struct NoGitProjectView: View {
    var body: some View {
        GuideView(
            systemImage: "folder.badge.questionmark",
            title: "此项目不是Git仓库",
            subtitle: "请选择一个包含Git仓库的项目，或在此项目中初始化Git仓库"
        )
    }
}

#Preview("NoGitProject") {
    RootView {
        NoGitProjectView()
    }
    .frame(height: 600)
    .frame(width: 600)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}