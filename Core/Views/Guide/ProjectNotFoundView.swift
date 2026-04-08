import LibGit2Swift
import MagicKit
import SwiftUI

/// 显示项目不存在时删除选项的视图组件
struct ProjectNotFoundView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "⚠️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 项目实例
    let project: Project

    var body: some View {
        MagicSettingSection(title: "项目状态", titleAlignment: .leading) {
            VStack(spacing: 0) {
                MagicSettingRow(
                    title: "项目路径不存在",
                    description: project.path,
                    icon: .iconFolder
                ) {
                    BtnDeleteProject(project: project)
                }

                Divider()

                MagicSettingRow(
                    title: "建议处理",
                    description: "删除该失效项目后重新添加正确路径",
                    icon: .iconSettings
                ) {
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}
