
import MagicKit
import OSLog
import SwiftUI

/// 删除项目按钮组件
struct BtnDeleteProject: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🗑️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var g: DataProvider

    /// 要删除的项目
    var project: Project

    var body: some View {
        Image.trash.inButtonWithAction {
            deleteItem(project)
        }
    }

    /// 删除项目
    /// - Parameter project: 要删除的项目
    private func deleteItem(_ project: Project) {
        withAnimation {
            g.deleteProject(project, using: g.repoManager.projectRepo)
        }
    }
}

// MARK: - Preview

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
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
