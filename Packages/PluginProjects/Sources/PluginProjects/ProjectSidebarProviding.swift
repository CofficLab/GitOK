import Combine
import Foundation
import LumiUI
import ProviderCloneRepository
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

    /// 克隆仓库能力（由 PluginCloneRepository 注册）；为 nil 时不显示克隆入口。
    private let cloneProvider: (any CloneRepositoryProviding)?

    public init(
        projects: any ProjectProviding,
        cloneProvider: (any CloneRepositoryProviding)? = nil
    ) {
        self.projects = projects
        self.cloneProvider = cloneProvider
    }

    public func registerItems(_ items: [SidebarItem]) {
        // 项目列表侧边栏不使用 SidebarItem 注入机制。
        self.items = items
    }

    public func activateItem(id: String?) {}

    public func makeSidebarView() -> AnyView {
        AnyView(ProjectSidebarView(projects: projects, cloneProvider: cloneProvider))
    }
}

/// 项目列表侧边栏视图：从 `ProjectProviding` 读取项目。
private struct ProjectSidebarView: View {
    let projects: any ProjectProviding
    let cloneProvider: (any CloneRepositoryProviding)?
    @StateObject private var observation: ProjectObservationModel
    @State private var searchText = ""
    @State private var isPresentingClone = false

    init(
        projects: any ProjectProviding,
        cloneProvider: (any CloneRepositoryProviding)?
    ) {
        self.projects = projects
        self.cloneProvider = cloneProvider
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    /// 过滤后的项目（仅在有搜索词时过滤）。
    private var filteredProjects: [Project] {
        let list = projects.projects
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return list }
        let needle = searchText.trimmingCharacters(in: .whitespaces)
        return list.filter { $0.title.localizedCaseInsensitiveContains(needle) }
    }

    var body: some View {
        AppSettingsSidebarContainer(width: 220) {
            VStack(spacing: 0) {
                // 搜索框常驻（对齐旧版顶部搜索）。
                AppSearchBar(text: $searchText, placeholder: "Search")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                Group {
                    if filteredProjects.isEmpty {
                        if projects.projects.isEmpty {
                            EmptyProjectsPlaceholder(projects: projects)
                        } else {
                            AppEmptyState(
                                icon: "magnifyingglass",
                                title: "No Results",
                                description: "No projects match \"\(searchText)\"."
                            )
                        }
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 2) {
                                ForEach(filteredProjects) { project in
                                    projectRow(project)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                // 底部操作栏：克隆仓库入口（由 PluginCloneRepository 提供）。
                if let cloneProvider {
                    AppDivider()
                    sidebarFooter(cloneProvider)
                }
            }
        }
        .frame(maxHeight: .infinity)
        .onReceive(observation.$revision) { _ in
            // 项目状态变化时重算 body，读取最新项目列表。
        }
        .sheet(isPresented: $isPresentingClone) {
            if let cloneProvider {
                cloneProvider.makeCloneSheetView()
            }
        }
    }

    /// 侧边栏底部操作栏（对齐旧版底部的项目操作区）。
    private func sidebarFooter(_ cloneProvider: any CloneRepositoryProviding) -> some View {
        HStack(spacing: 8) {
            Spacer()
            AppButton(
                "Clone Repository",
                systemImage: "arrow.triangle.branch",
                style: .secondary,
                size: .small
            ) {
                isPresentingClone = true
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
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

/// 侧边栏暂无项目时的占位视图（对齐旧版 Onboarding 空态引导）。
private struct EmptyProjectsPlaceholder: View {
    let projects: any ProjectProviding

    init(projects: any ProjectProviding) {
        self.projects = projects
    }

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 24)
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            VStack(spacing: 4) {
                Text("Get Started with GitOK")
                    .font(.callout.weight(.semibold))
                Text("Add an existing repository, or clone a new one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 170)
            }
            AppButton(
                "Add Project",
                systemImage: "folder",
                style: .primary,
                size: .small
            ) {
                addExistingProject()
            }
            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func addExistingProject() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Add"
        panel.message = "Choose a repository folder to add to GitOK"
        if panel.runModal() == .OK, let url = panel.url {
            projects.addProject(at: url)
            projects.openProject(at: url)
        }
    }
}
