import Combine
import Foundation
import LumiUI
import ProviderProjects
import ProviderSidebar
import SwiftUI

/// `SidebarProviding` 的项目列表实现。
///
/// 视图从 `ProjectProviding` 读取项目列表（只依赖契约，不依赖具体实现），
/// 渲染为左侧项目列表侧边栏。这是 Lumi 架构的典型用法：
/// Provider 声明能力，Plugin 跨 Provider 组装。
@MainActor
public final class ProjectSidebarProviding: SidebarProviding, ObservableObject {
    @Published public private(set) var items: [SidebarItem] = []

    /// 项目数据源（契约）。
    private let projects: any ProjectProviding

    public init(projects: any ProjectProviding) {
        self.projects = projects
    }

    public func registerItems(_ items: [SidebarItem]) {
        // 项目列表侧边栏不使用 SidebarItem 注入机制。
        self.items = items
    }

    public func activateItem(id: String?) {}

    public func makeSidebarView() -> AnyView {
        AnyView(ProjectSidebarView(projects: projects))
    }
}

/// 项目列表侧边栏视图：从 `ProjectProviding` 读取项目。
private struct ProjectSidebarView: View {
    let projects: any ProjectProviding

    var body: some View {
        AppSettingsSidebarContainer(width: 220) {
            Group {
                if projects.projects.isEmpty {
                    EmptyProjectsPlaceholder()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 2) {
                            ForEach(projects.projects) { project in
                                projectRow(project)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
        .onReceive(projects.objectWillChange) { _ in
            // objectWillChange 触发时重算 body，读取最新项目列表。
        }
    }

    private func projectRow(_ project: Project) -> some View {
        AppSettingsSidebarItem(
            title: project.title,
            systemImage: "folder",
            isSelected: projects.currentProject?.id == project.id
        ) {
            projects.openProject(at: project.url)
        }
        .id(project.id)
        .contextMenu {
            Button {
                projects.removeProject(id: project.id)
            } label: {
                Label("Remove Project", systemImage: "trash")
            }
        }
    }
}

/// 侧边栏暂无项目时的占位视图。
private struct EmptyProjectsPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No Projects")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
