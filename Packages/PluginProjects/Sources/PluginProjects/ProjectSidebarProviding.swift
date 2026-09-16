import AppKit
import Combine
import Foundation
import LumiUI
import ProviderActivity
import ProviderCloneRepository
import ProviderGit
import ProviderProjects
import ProviderSidebar
import ProviderToast
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

    /// 克隆所需的 Git 与反馈能力。Git 不可用时隐藏克隆按钮。
    private let git: (any GitProviding)?
    private let activity: (any ActivityProviding)?
    private let toast: (any ToastProviding)?
    private let cloneRepository: (any CloneRepositoryProviding)?

    public init(
        projects: any ProjectProviding,
        git: (any GitProviding)? = nil,
        activity: (any ActivityProviding)? = nil,
        toast: (any ToastProviding)? = nil,
        cloneRepository: (any CloneRepositoryProviding)? = nil
    ) {
        self.projects = projects
        self.git = git
        self.activity = activity
        self.toast = toast
        self.cloneRepository = cloneRepository
    }

    public func registerItems(_ items: [SidebarItem]) {
        // 项目列表侧边栏不使用 SidebarItem 注入机制。
        self.items = items
    }

    public func activateItem(id: String?) {}

    public func makeSidebarView() -> AnyView {
        AnyView(
            ProjectSidebarView(
                projects: projects,
                git: git,
                activity: activity,
                toast: toast,
                cloneRepository: cloneRepository
            )
        )
    }
}

/// 项目列表侧边栏视图：从 `ProjectProviding` 读取项目。
private struct ProjectSidebarView: View {
    let projects: any ProjectProviding
    let git: (any GitProviding)?
    let activity: (any ActivityProviding)?
    let toast: (any ToastProviding)?
    let cloneRepository: (any CloneRepositoryProviding)?
    @StateObject private var observation: ProjectObservationModel
    @State private var searchText = ""
    @State private var isPresentingClone = false

    init(
        projects: any ProjectProviding,
        git: (any GitProviding)?,
        activity: (any ActivityProviding)?,
        toast: (any ToastProviding)?,
        cloneRepository: (any CloneRepositoryProviding)?
    ) {
        self.projects = projects
        self.git = git
        self.activity = activity
        self.toast = toast
        self.cloneRepository = cloneRepository
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
        VStack(spacing: 0) {
            // 搜索框 + 克隆项目 + 添加项目
            HStack(spacing: 4) {
                AppSearchBar(text: $searchText, placeholder: LocalizedStringKey(LumiPluginLocalization.string("Search", bundle: .module)))
                if git != nil, cloneRepository != nil {
                    AppIconButton(systemImage: "arrow.down.circle", size: .compact) {
                        isPresentingClone = true
                    }
                    .help(LumiPluginLocalization.string("Clone Repository", bundle: .module))
                }
                AppIconButton(systemImage: "plus", size: .compact) {
                    addExistingProject()
                }
                .help(LumiPluginLocalization.string("Add Project", bundle: .module))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            Group {
                if filteredProjects.isEmpty {
                    if projects.projects.isEmpty {
                        EmptyProjectsPlaceholder(projects: projects)
                    } else {
                        AppEmptyState(
                            icon: "magnifyingglass",
                            title: LumiPluginLocalization.string("No Results", bundle: .module),
                            description: String(format: LumiPluginLocalization.string("No projects match \"%@\".", bundle: .module), searchText)
                        )
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(filteredProjects.enumerated()), id: \.element.id) { index, project in
                                projectRow(project, isLastPinned: index == (pinnedDividerIndex ?? Int.max) - 1)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    }
                }
            }
            .frame(maxHeight: .infinity)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background.opacity(0.6))
        .frame(maxHeight: .infinity)
        .onReceive(observation.$revision) { _ in
            // 项目状态变化时重算 body，读取最新项目列表。
        }
        .sheet(isPresented: $isPresentingClone) {
            if let git, let cloneRepository {
                CloneRepositorySheet(
                    projects: projects,
                    toast: toast,
                    git: git,
                    cloneRepository: cloneRepository
                )
            }
        }
    }

    /// 置顶项目与未置顶项目的分界索引（用于插入分隔线）。
    private var pinnedDividerIndex: Int? {
        let list = filteredProjects
        guard !list.isEmpty else { return nil }
        let hasPinned = list.contains(where: \.isPinned)
        let hasUnpinned = list.contains(where: { !$0.isPinned })
        guard hasPinned && hasUnpinned else { return nil }
        // 第一个非置顶项的位置。
        return list.firstIndex(where: { !$0.isPinned })
    }

    private func projectRow(_ project: Project, isLastPinned: Bool = false) -> some View {
        AppSettingsSidebarItem(
            title: project.title,
            systemImage: project.isPinned ? "pin.fill" : "folder",
            isSelected: projects.currentProject?.id == project.id
        ) {
            projects.openProject(at: project.url)
        }
        .id(project.id)
        .contextMenu {
            Button {
                projects.pinProject(id: project.id, isPinned: !project.isPinned)
            } label: {
                Label(
                    LumiPluginLocalization.string(project.isPinned ? "Unpin" : "Pin to Top", bundle: .module),
                    systemImage: project.isPinned ? "pin.slash" : "pin"
                )
            }

            Divider()

            Button {
                copyProjectPath(project)
            } label: {
                Label(
                    LumiPluginLocalization.string("Copy Project Path", bundle: .module),
                    systemImage: "doc.on.doc"
                )
            }

            Button {
                openProjectInFinder(project)
            } label: {
                Label(
                    LumiPluginLocalization.string("Open in Finder", bundle: .module),
                    systemImage: "folder"
                )
            }

            Divider()

            Button {
                projects.removeProject(id: project.id)
            } label: {
                Label(LumiPluginLocalization.string("Remove Project", bundle: .module), systemImage: "trash")
            }
        }
        .overlay(alignment: .bottom) {
            if isLastPinned {
                AppDivider().padding(.vertical, 2)
            }
        }
    }

    private func copyProjectPath(_ project: Project) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(project.url.path, forType: .string)
    }

    private func openProjectInFinder(_ project: Project) {
        NSWorkspace.shared.activateFileViewerSelecting([project.url])
    }

    private func addExistingProject() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = LumiPluginLocalization.string("Add", bundle: .module)
        panel.message = LumiPluginLocalization.string("Choose a repository folder to add to GitOK", bundle: .module)
        if panel.runModal() == .OK, let url = panel.url {
            projects.addProject(at: url)
            projects.openProject(at: url)
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
                Text(LumiPluginLocalization.string("Get Started with GitOK", bundle: .module))
                    .font(.callout.weight(.semibold))
                Text(LumiPluginLocalization.string("Add an existing repository, or clone a new one.", bundle: .module))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 170)
            }
            AppButton(
                LumiPluginLocalization.string("Add Project", bundle: .module),
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
        panel.prompt = LumiPluginLocalization.string("Add", bundle: .module)
        panel.message = LumiPluginLocalization.string("Choose a repository folder to add to GitOK", bundle: .module)
        if panel.runModal() == .OK, let url = panel.url {
            projects.addProject(at: url)
            projects.openProject(at: url)
        }
    }
}
