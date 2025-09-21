import MagicCore
import MagicUI
import MagicBackground
import OSLog
import SwiftUI

/**
 * 删除项目按钮组件
 */
struct BtnDeleteProject: View {
    @EnvironmentObject var g: DataProvider

    var project: Project

    var body: some View {
        MagicButton {_ in 
            deleteItem(project)
        }
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
