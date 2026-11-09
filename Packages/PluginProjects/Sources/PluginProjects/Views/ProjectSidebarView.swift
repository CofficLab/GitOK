import AppKit
import Combine
import Foundation
import KitOpenIn
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
    /// 项目活跃度模型：仅在「最近更新」展示方式下读取仓库提交时间。
    @StateObject private var activity: ProjectActivityModel
    /// 项目所在卷模型：缓存外接卷 / 不可访问状态，供行内徽标使用。
    @StateObject private var volume: ProjectVolumeModel
    @LumiTheme private var theme
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
    /// 当前项目列表的展示方式（排序规则）。
    @State private var sortMode: ProjectSortMode = .manual
    /// 展示方式的持久化存储。
    private let sortModeStore: any ProjectSortModeStoring

    /// re-clone 状态机；仅在 Git 与克隆 Provider 都可用时创建。
    @State private var reclone: ProjectsRecloneCoordinator?

    init(
        projects: any ProjectSidebarCapability,
        toast: (any ToastProviding)?,
        clone: ProjectCloneCapability?,
        remoteCapability: (any GitRemoteCapability)?,
        activityCapability: (any ProjectActivityCapability)? = nil,
        sortModeStore: (any ProjectSortModeStoring)? = nil
    ) {
        self.projects = projects
        self.toast = toast
        self.clone = clone
        self.remoteCapability = remoteCapability
        // 未注入存储时退化为纯内存模式（预览 / 测试场景）：排序偏好可读可写，
        // 只是不落盘。
        self.sortModeStore = sortModeStore ?? InMemoryProjectSortModeStore()
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
        _activity = StateObject(wrappedValue: ProjectActivityModel(capability: activityCapability))
        _volume = StateObject(wrappedValue: ProjectVolumeModel())
        // 恢复上次选择的展示方式；读不到时回落到手动排序。
        _sortMode = State(initialValue: self.sortModeStore.loadSortMode() ?? .manual)
    }

    // MARK: - Derived State

    /// 过滤后的项目（仅在有搜索词时过滤）。
    private var filteredProjects: [Project] {
        let list = projects.projects
        let needle = searchText.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else {
            return sortMode.sorted(list, commitDates: activity.commitDates)
        }
        let matched = list.filter { $0.title.localizedCaseInsensitiveContains(needle) }
        return sortMode.sorted(matched, commitDates: activity.commitDates)
    }

    /// 当前展示方式是否允许拖拽调整顺序。
    ///
    /// 只有手动排序下拖拽才有意义：其他展示方式里列表顺序由规则决定，
    /// 拖拽改变的是「手动顺序」而不会立刻反映到界面上，容易让用户困惑。
    private var supportsManualReordering: Bool {
        sortMode == .manual
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

    /// 置顶项目数量（仅在 2 个以上时才展示「取消全部置顶」）。
    private var pinnedProjectCount: Int {
        projects.projects.filter(\.isPinned).count
    }

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
                // 新增 / 移除项目后，「最近更新」需要为新项目补读提交时间。
                refreshActivityIfNeeded()
                volume.refresh(for: projects.projects)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                // 应用回到前台：卷可能已被插拔，重新判定一次。
                volume.refresh(for: projects.projects, force: true)
                // 在 GitOK 之外提交的仓库不会触发项目事件，排序键只能靠
                // 回到前台时强制重读才会跟上。
                refreshActivityIfNeeded(force: true)
            }
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didMountNotification)) { _ in
                volume.refresh(for: projects.projects, force: true)
            }
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didUnmountNotification)) { _ in
                volume.refresh(for: projects.projects, force: true)
            }
            .onAppear {
                ensureRecloneCoordinator()
                volume.refresh(for: projects.projects)
            }
            .onDisappear {
                volume.cancel()
            }
            .onChange(of: sortMode) { _, newMode in
                sortModeStore.saveSortMode(newMode)
                // 切换到「最近更新」时按需读取仓库提交时间；其他方式不需要。
                refreshActivityIfNeeded()
            }
            .task(id: sortMode) {
                refreshActivityIfNeeded()
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

            // 底部展示方式切换栏：项目变多后用于快速切换列表的排列规则。
            ProjectSortBarView(
                mode: $sortMode,
                projectCount: projects.projects.count,
                isLoadingActivity: sortMode.requiresCommitActivity
                    && !activity.loadingProjectIDs.isEmpty
            )
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
                // 仅在手动排序下启用拖拽：其他展示方式的顺序由规则决定。
                if supportsManualReordering {
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
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    private func projectRow(_ project: Project) -> some View {
        projectRowContent(project)
            .modifier(ProjectDragModifier(
                isEnabled: supportsManualReordering,
                projectID: project.id,
                draggedProjectID: $draggedProjectID,
                onMove: moveProject
            ))
    }

    /// 项目行内容（不含拖拽）。
    ///
    /// 与 `AppSettingsSidebarItem` 保持相同的行高、图标尺寸和选中样式，
    /// 额外在标题尾部预留卷状态徽标的位置。
    private func projectRowContent(_ project: Project) -> some View {
        Button {
            projects.openProject(at: project.url)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: project.isPinned ? "pin.fill" : "folder")
                    .frame(width: 18, alignment: .center)
                Text(project.title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 4)
                if let badge = volumeBadge(for: project) {
                    projectVolumeBadge(badge)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .appSurface(
            style: .custom(
                projects.currentProject?.id == project.id
                    ? Color.secondary.opacity(0.25)
                    : Color.clear
            ),
            cornerRadius: 6
        )
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

            if pinnedProjectCount > 1 {
                Button {
                    unpinAllProjects()
                } label: {
                    Label(
                        pluginLocalization.string("Unpin All"),
                        systemImage: "pin.slash"
                    )
                }
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

            Button {
                openProjectInTerminal(project)
            } label: {
                Label(
                    pluginLocalization.string("Open in Terminal"),
                    systemImage: "terminal"
                )
            }
            .disabled(!isTerminalAvailable)

            Divider()

            Button {
                projects.removeProject(id: project.id)
            } label: {
                Label(pluginLocalization.string("Remove Project"), systemImage: "trash")
            }
        }
    }

    private func moveProject(_ draggedID: UUID, before targetID: UUID?) {
        projects.moveProject(id: draggedID, beforeID: targetID)
    }

    // MARK: - Volume Badge

    /// 非本机卷或不可访问时才返回徽标，避免本机项目出现多余装饰。
    private func volumeBadge(for project: Project) -> ProjectVolumeBadge? {
        let badge = volume.badge(for: project.id)
        return badge == .none ? nil : badge
    }

    @ViewBuilder
    private func projectVolumeBadge(_ badge: ProjectVolumeBadge) -> some View {
        switch badge {
        case .none:
            EmptyView()
        case .external:
            Image(systemName: "externaldrive.fill")
                .font(.appMicro)
                .foregroundStyle(theme.textSecondary)
                .help(pluginLocalization.string("Stored on an external drive"))
                .accessibilityLabel(pluginLocalization.string("External Drive"))
        case .unavailable:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.appMicroEmphasized)
                .foregroundStyle(theme.warning)
                .help(pluginLocalization.string("This project is on a volume that is not currently available."))
                .accessibilityLabel(pluginLocalization.string("Volume not available"))
        }
    }

    /// 取消全部置顶（保留项目原有相对顺序）。
    private func unpinAllProjects() {
        for project in projects.projects where project.isPinned {
            projects.pinProject(id: project.id, isPinned: false)
        }
    }

    // MARK: - Activity

    /// 按当前展示方式决定是否读取仓库提交时间。
    ///
    /// 只有「最近更新」需要提交时间；其余展示方式不启动任何 git 进程。
    /// 已缓存的结果会被复用，重复切换不会重复读取。
    ///
    /// - Parameter force: 忽略缓存重新读取全部项目，用于感知外部提交。
    private func refreshActivityIfNeeded(force: Bool = false) {
        guard sortMode.requiresCommitActivity else {
            activity.cancel()
            return
        }
        activity.refresh(for: projects.projects, force: force)
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

    /// 在终端中打开项目目录。
    ///
    /// 复用 `KitOpenIn` 的 `AppLauncher`（与工具栏「Open Terminal」按钮同一条链路），
    /// 由系统 Terminal 负责在新窗口中定位到项目目录。
    private func openProjectInTerminal(_ project: Project) {
        AppLauncher.open(.terminal, projectURL: project.url)
    }

    /// 终端应用是否可用；未安装时右键菜单项置灰。
    private var isTerminalAvailable: Bool {
        AppLauncher.isInstalled(.terminal)
    }
}