import SwiftUI

/// 无项目提示视图
/// 当没有选择项目时显示此视图
struct NoProjectView: View {
    var body: some View {
        GuideView(
            systemImage: "folder",
            title: "请选择项目",
            subtitle: "请从左侧选择一个项目开始使用"
        )
    }
}

#Preview("NoCommit") {
    RootView {
        NoProject()
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
