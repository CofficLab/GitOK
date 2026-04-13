import MagicKit
import OSLog
import SwiftData
import SwiftUI

/// 项目列表视图
struct Projects: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🖥️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 数据提供者环境对象
    @EnvironmentObject var data: DataVM

    /// 当前项目状态
    @EnvironmentObject var projectVM: ProjectVM

    /// 当前选中的项目
    @State var selection: Project? = nil

    /// 搜索文本
    @State private var searchText = ""

    /// 过滤后的项目列表
    private var filteredProjects: [Project] {
        if searchText.isEmpty {
            return data.projects
        }
        return data.projects.filter { project in
            project.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// 视图主体
    var body: some View {
        VStack(spacing: 0) {
            // 搜索框 - 仅在项目数超过10个时显示
            if data.projects.count > 10 {
                AppSearchBar(text: $searchText, placeholder: "Search...")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }

            // 项目列表
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredProjects, id: \.self) { item in
                        ProjectRow(
                            title: item.title,
                            isSelected: selection == item
                        ) {
                            selection = item
                            projectVM.setProject(item, reason: self.className)
                        }
                        .contextMenu { ProjectContextMenu(item: item, pinAction: pinItem, deleteAction: deleteItem) }
                    }
                }
                .padding(.horizontal, 8)
            }
            .onAppear(perform: onAppear)
            .onChange(of: projectVM.project) { newProject in
                // 当 projectVM.project 被外部改变时（如 Dock 拖拽），同步 selection 高亮
                if selection != newProject {
                    selection = newProject
                }
            }
        }
    }
}
