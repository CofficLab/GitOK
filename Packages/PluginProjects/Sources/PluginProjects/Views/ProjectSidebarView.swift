import AppKit
import Combine
import Foundation
import LumiUI
import ProviderProjects
import ProviderToast
import SwiftUI
import UniformTypeIdentifiers

/// 项目列表侧边栏视图：从 `ProjectProviding` 读取项目。
///
/// 本视图只负责渲染与用户意图派发：列表、搜索、右键菜单、拖拽、克隆入口和
/// 各类 alert。re-clone 的异步状态机由 `ProjectsRecloneCoordinator` 持有，
/// 本视图仅根据它的 `state` 决定弹哪个确认框。
struct ProjectSidebarView: View {
    let projects: any ProjectSidebarCapability
    let toast: (any ToastProviding)?
    let clone: ProjectCloneCapability?
    let remoteCapability: (any GitRemoteCapability)?

    @StateObject private var observation: ProjectObservationModel
    @State private var searchText = ""
    @State private var isPresentingClone = false
    /// 待重命名的项目（非 nil 时弹出重命名输入框）。
    @State private var projectPendingRename: Project?
    @State private var renameText = ""
    @State private var renameErrorMessage: String?
    @State private var isPresentingRenameError = false
    @State private var draggedProjectID: UUID?
    /// `prepare` 阶段的前置校验失败（无 remote / 目标非法）。
    @State private var preparationErrorMessage: String?
    @State private var isPresentingPreparationError = false

    /// re-clone 状态机；仅在 Git 与克隆 Provider 都可用时创建。
    @State private var reclone: ProjectsRecloneCoordinator?

    init(
        projects: any ProjectSidebarCapability,
        toast: (any ToastProviding)?,
        clone: ProjectCloneCapability?,
        remoteCapability: (any GitRemoteCapability)?
    ) {
        self.projects = projects
        self.toast = toast
        self.clone = clone
        self.remoteCapability = remoteCapability
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    // MARK: - Derived State

    /// 过滤后的项目（仅在有搜索词时过滤）。
    private var filteredProjects: [Project] {
        let list = projects.projects
        let needle = searchText.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return list }
        return list.filter { $0.title.localizedCaseInsensitiveContains(needle) }
    }

    /// 置顶项目与未置顶项目的分界索引（用于插入分隔线）。
    private var pinnedDividerIndex: Int? {
        let list = filteredProjects
        guard !list.isEmpty else { return nil }
        let hasPinned = list.contains(where: \.isPinned)
        let hasUnpinned = list.contains(where: { !$0.isPinned })
        guard hasPinned && hasUnpinned else { return nil }
        return list.firstIndex(where: { !$0.isPinned })
    }

    /// 是否具备克隆能力（克隆 Provider 已注册）。
    private var canClone: Bool { clone != nil }

    /// 当前进行中的 re-clone 任务；驱动 `.task(id:)` 启停轮询。
    private var recloneTaskID: UUID? {
        guard case let .running(taskID) = reclone?.state else { return nil }
        return taskID
    }

    private var isConfirmingReclone: Bool {
        if case .confirming = reclone?.state { return true }
        return false
    }

    private var confirmingProject: Project? {
        guard case let .confirming(project, _) = reclone?.state else { return nil }
        return project
    }

    private var confirmingRemoteURL: String {
        guard case let .confirming(_, remoteURL) = reclone?.state else { return "" }
        return remoteURL
    }

    private var recloneFailureMessage: String? {
        guard case let .failed(message) = reclone?.state else { return nil }
        return message
    }

    // MARK: - Body

    var body: some View {
        layout
            .onReceive(observation.$revision) { _ in
                // 项目状态变化时重算 body，读取最新项目列表。
            }
            .onAppear {
                ensureRecloneCoordinator()
            }
            .task(id: recloneTaskID) {
                guard let reclone, let recloneTaskID else { return }
                await reclone.run(taskID: recloneTaskID)
            }
            .sheet(isPresented: $isPresentingClone) {
                if let clone {
                    CloneRepositorySheet(
                        projects: projects,
                        toast: toast,
                        clone: clone
                    )
                }
            }
            .alert(
                pluginLocalization.string("Re-clone Project"),
                isPresented: isConfirmingReclonePresented,
                presenting: confirmingProject
            ) { _ in
                Button(pluginLocalization.string("Re-clone"), role: .destructive) {
                    reclone?.beginReclone()
                }
                Button(pluginLocalization.string("Cancel"), role: .cancel) {
                    reclone?.cancelConfirmation()
                }
            } message: { project in
                Text(
                    String(
                        format: pluginLocalization.string(
                            "This will delete the local project at \"%@\" and replace it with a fresh clone from \"%@\". Uncommitted changes will be lost."
                        ),
                        project.url.path,
                        confirmingRemoteURL
                    )
                )
            }
            .alert(
                pluginLocalization.string("Re-clone Failed"),
                isPresented: isPresentingRecloneFailure
            ) {
                Button(pluginLocalization.string("OK"), role: .cancel) {
                    reclone?.dismissFailure()
                }
            } message: {
                Text(recloneFailureMessage ?? "")
            }
            .alert(
                pluginLocalization.string("Re-clone Failed"),
                isPresented: $isPresentingPreparationError
            ) {
                Button(pluginLocalization.string("OK"), role: .cancel) {}
            } message: {
                Text(preparationErrorMessage ?? "")
            }
            .alert(
                pluginLocalization.string("Rename Project"),
                isPresented: renameAlertPresented,
                presenting: projectPendingRename
            ) { _ in
                TextField(pluginLocalization.string("Project Name"), text: $renameText)
                Button(pluginLocalization.string("Rename")) {
                    performRename()
                }
                Button(pluginLocalization.string("Cancel"), role: .cancel) {}
            } message: { project in
                Text(project.url.path)
            }
            .alert(
                pluginLocalization.string("Rename Failed"),
                isPresented: $isPresentingRenameError
            ) {
                Button(pluginLocalization.string("OK"), role: .cancel) {}
            } message: {
                Text(renameErrorMessage ?? "")
            }
    }

    // MARK: - Layout

    private var layout: some View {
        VStack(spacing: 0) {
            toolbar
            Group {
                if filteredProjects.isEmpty {
                    if projects.projects.isEmpty {
                        EmptyProjectsPlaceholder(projects: projects)
                    } else {
                        AppEmptyState(
                            icon: "magnifyingglass",
                            title: pluginLocalization.string("No Results"),
                            description: String(
                                format: pluginLocalization.string("No projects match \"%@\"."),
                                searchText
                            )
                        )
                    }
                } else {
                    projectList
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background.opacity(0.6))
    }

    private var toolbar: some View {
        HStack(spacing: 4) {
            AppSearchBar(
                text: $searchText,
                placeholder: LocalizedStringKey(pluginLocalization.string("Search"))
            )
            if canClone {
                AppIconButton(systemImage: "arrow.down.circle", size: .compact) {
                    isPresentingClone = true
                }
                .help(pluginLocalization.string("Clone Repository"))
                .accessibilityLabel(pluginLocalization.string("Clone Repository"))
                .accessibilityIdentifier("gitok.projects.clone")
            }
            AppIconButton(systemImage: "plus", size: .compact) {
                ProjectPicker.addExistingProject(to: projects)
            }
            .help(pluginLocalization.string("Add Project"))
            .accessibilityLabel(pluginLocalization.string("Add Project"))
            .accessibilityIdentifier("gitok.projects.add")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var projectList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 2) {
                ForEach(Array(filteredProjects.enumerated()), id: \.element.id) { index, project in
                    projectRow(project)
                    if index == (pinnedDividerIndex ?? Int.max) - 1 {
                        AppDivider().padding(.horizontal, 8)
                    }
                }

                // 允许把项目拖到分组末尾；项目管理器会根据置顶状态
                // 将其插入对应分组末尾，不会破坏置顶区边界。
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 16)
                    .contentShape(Rectangle())
                    .onDrop(
                        of: [.text],
                        delegate: ProjectDropDelegate(
                            draggedProjectID: draggedProjectID,
                            targetProjectID: nil,
                            onMove: moveProject
                        )
                    )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    private func projectRow(_ project: Project) -> some View {
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
                    pluginLocalization.string(project.isPinned ? "Unpin" : "Pin to Top"),
                    systemImage: project.isPinned ? "pin.slash" : "pin"
                )
            }

            if canClone {
                Divider()

                Button(role: .destructive) {
                    presentRecloneConfirmation(for: project)
                } label: {
                    Label(
                        pluginLocalization.string("Re-clone Project"),
                        systemImage: "arrow.clockwise"
                    )
                }
                .disabled(reclone?.isRunning ?? false)
            }

            Button {
                renameText = project.title
                projectPendingRename = project
            } label: {
                Label(
                    pluginLocalization.string("Rename Project"),
                    systemImage: "pencil"
                )
            }

            Divider()

            Button {
                copyProjectPath(project)
            } label: {
                Label(
                    pluginLocalization.string("Copy Project Path"),
                    systemImage: "doc.on.doc"
                )
            }

            Button {
                openProjectInFinder(project)
            } label: {
                Label(
                    pluginLocalization.string("Open in Finder"),
                    systemImage: "folder"
                )
            }

            Divider()

            Button {
                projects.removeProject(id: project.id)
            } label: {
                Label(pluginLocalization.string("Remove Project"), systemImage: "trash")
            }
        }
        .onDrag {
            draggedProjectID = project.id
            return NSItemProvider(object: NSString(string: project.id.uuidString))
        }
        .onDrop(
            of: [.text],
            delegate: ProjectDropDelegate(
                draggedProjectID: draggedProjectID,
                targetProjectID: project.id,
                onMove: moveProject
            )
        )
    }

    private func moveProject(_ draggedID: UUID, before targetID: UUID?) {
        projects.moveProject(id: draggedID, beforeID: targetID)
    }

    // MARK: - Re-clone

    /// 首次进入视图时惰性创建协调器，避免在 Git / 克隆 Provider 缺失时构造。
    private func ensureRecloneCoordinator() {
        guard reclone == nil, let clone, let remoteCapability else { return }
        reclone = ProjectsRecloneCoordinator(
            git: remoteCapability,
            clone: clone,
            onProjectReplaced: { [projects] in projects.notifyDataChanged() }
        )
    }

    private func presentRecloneConfirmation(for project: Project) {
        do {
            try reclone?.prepare(project)
        } catch {
            preparationErrorMessage = error.localizedDescription
            isPresentingPreparationError = true
        }
    }

    private var isConfirmingReclonePresented: Binding<Bool> {
        Binding(
            get: { isConfirmingReclone },
            set: { if !$0 { reclone?.cancelConfirmation() } }
        )
    }

    private var isPresentingRecloneFailure: Binding<Bool> {
        Binding(
            get: { recloneFailureMessage != nil },
            set: { if !$0 { reclone?.dismissFailure() } }
        )
    }

    // MARK: - Rename

    private var renameAlertPresented: Binding<Bool> {
        Binding(
            get: { projectPendingRename != nil },
            set: { if !$0 { projectPendingRename = nil } }
        )
    }

    /// 执行重命名：调用 `ProjectProviding.renameProject`，失败时展示错误弹窗。
    private func performRename() {
        guard let project = projectPendingRename else { return }
        do {
            try projects.renameProject(id: project.id, newName: renameText)
        } catch {
            renameErrorMessage = error.localizedDescription
            isPresentingRenameError = true
        }
    }

    // MARK: - Utilities

    private func copyProjectPath(_ project: Project) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(project.url.path, forType: .string)
    }

    private func openProjectInFinder(_ project: Project) {
        NSWorkspace.shared.activateFileViewerSelecting([project.url])
    }
}