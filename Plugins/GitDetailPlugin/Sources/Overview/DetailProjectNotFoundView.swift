import GitOKAppCore
import GitOKSupportKit
import GitOKUI
import SwiftUI

struct DetailProjectNotFoundView: View, SuperLog {
    nonisolated static let emoji = "⚠️"
    nonisolated static let verbose = false

    let project: Project

    @EnvironmentObject private var data: DataVM

    var body: some View {
        AppSettingSection(title: "项目状态", titleAlignment: .leading) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: "项目路径不存在",
                    description: project.path,
                    icon: .iconFolder
                ) {
                    AppIconButton(systemImage: "trash", size: .regular) {
                        withAnimation {
                            data.deleteProject(project, using: data.repoManager.projectRepo)
                        }
                    }
                }

                Divider()

                AppSettingRow(
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
