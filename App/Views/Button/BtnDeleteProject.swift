import MagicCore
import OSLog
import SwiftUI

/**
 * 删除项目按钮组件
 */
struct BtnDeleteProject: View {
    @EnvironmentObject var g: DataProvider

    var project: Project

    var body: some View {
        MagicButton(action: {
            deleteItem(project)
        })
        .magicTitle("删除项目")
        .magicSize(.auto)
        .magicBackground(MagicBackground.cherry)
    }

    /**
     * 删除项目
     * @param project 要删除的项目
     */
    private func deleteItem(_ project: Project) {
        withAnimation {
            g.deleteProject(project, using: g.repoManager.projectRepo)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
