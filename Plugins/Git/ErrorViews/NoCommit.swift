import SwiftUI

/// 无提交记录提示视图
/// 当 Git 仓库没有提交记录时显示此视图
struct NoCommit: View {
    var body: some View {
        GuideView(
            systemImage: "doc.text.magnifyingglass",
            title: String(localized: "select_commit_title"),
            subtitle: String(localized: "select_commit_description")
        )
    }
}

#Preview("NoCommit") {
    RootView {
        NoCommit()
    }
    .frame(height: 600)
    .frame(width: 600)
}

#Preview("App") {
    RootView {
        ContentView()
            .hideSidebar()
    }
    .frame(height: 600)
    .frame(width: 600)
}

#Preview("Default-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
