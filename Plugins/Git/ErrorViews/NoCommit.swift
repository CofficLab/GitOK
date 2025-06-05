import SwiftUI

/// 无提交记录提示视图
/// 当 Git 仓库没有提交记录时显示此视图
struct NoCommit: View {
    @EnvironmentObject var g: GitProvider

    var body: some View {
        VStack(spacing: 20) {
            GuideView(
                systemImage: "doc.text.magnifyingglass",
                title: String(localized: "select_commit_title"),
                subtitle: String(localized: "select_commit_description")
            )

            if let projectPath = g.project?.path {
                Text("当前项目：\(projectPath)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
