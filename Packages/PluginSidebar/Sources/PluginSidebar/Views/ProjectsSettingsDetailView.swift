import LumiUI
import ProviderProjects
import SwiftUI

/// 设置窗口「项目」标签页 —— 展示现有项目列表。
///
/// 从 `ProjectProviding` 读取项目，每行一个项目（文件夹图标 + 标题 + 路径），
/// 右侧提供「打开」操作。数据变化时通过 `objectWillChange` 触发重算。
struct ProjectsSettingsDetailView: View {
    let projects: any ProjectProviding

    var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 24) {
                AppSettingSection(
                    title: "项目",
                    titleAlignment: .leading
                ) {
                    if projects.projects.isEmpty {
                        emptyState
                    } else {
                        projectList
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onReceive(projects.objectWillChange) { _ in
            // 触发 body 重算，读取最新项目列表。
        }
    }

    // MARK: - 项目列表

    private var projectList: some View {
        VStack(spacing: 0) {
            ForEach(projects.projects) { project in
                AppSettingRow(
                    title: project.title,
                    description: project.url.path,
                    icon: "folder"
                ) {
                    AppButton(
                        "打开",
                        systemImage: "arrow.up.forward",
                        style: .secondary,
                        size: .small
                    ) {
                        projects.openProject(at: project.url)
                    }
                }
                if project.id != projects.projects.last?.id {
                    Divider()
                        .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - 空状态

    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.badge.plus")
                .foregroundStyle(.secondary)
            Text("暂无项目")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
