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
import UniformTypeIdentifiers

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
    /// 待重命名的项目（非 nil 时弹出重命名输入框）。
    @State private var projectPendingRename: Project?
    @State private var renameText = ""
    @State private var renameErrorMessage: String?
    @State private var isPresentingRenameError = false
    @State private var draggedProjectID: UUID?
    @State private var projectPendingReclone: Project?
    @State private var recloneRemoteURL: String?
    @State private var recloneTaskID: UUID?
    @State private var recloneProject: Project?
    @State private var recloneDestination: URL?
    @State private var recloneErrorMessage: String?
    @State private var isPresentingRecloneError = false

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
                    .accessibilityLabel(LumiPluginLocalization.string("Clone Repository", bundle: .module))
                    .accessibilityIdentifier("gitok.projects.clone")
                }
                AppIconButton(systemImage: "plus", size: .compact) {
                    addExistingProject()
                }
                .help(LumiPluginLocalization.string("Add Project", bundle: .module))
                .accessibilityLabel(LumiPluginLocalization.string("Add Project", bundle: .module))
                .accessibilityIdentifier("gitok.projects.add")
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

                            // 允许把项目拖到分组末尾；项目管理器会根据项目的置顶状态
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
            }
            .frame(maxHeight: .infinity)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background.opacity(0.6))
        .frame(maxHeight: .infinity)
        .onReceive(observation.$revision) { _ in
            // 项目状态变化时重算 body，读取最新项目列表。
        }
        .task(id: recloneTaskID) {
            guard let recloneTaskID else { return }
            await monitorReclone(taskID: recloneTaskID)
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
        // 重命名输入：预填当前名称，确认后执行磁盘重命名。
        .alert(
            LumiPluginLocalization.string("Rename Project", bundle: .module),
            isPresented: renameAlertPresented,
            presenting: projectPendingRename
        ) { _ in
            TextField(LumiPluginLocalization.string("Project Name", bundle: .module), text: $renameText)
            Button(LumiPluginLocalization.string("Rename", bundle: .module)) {
                performRename()
            }
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {}
        } message: { project in
            Text(project.url.path)
        }
        // 重命名失败（非法名称 / 目标已存在 / 磁盘错误）提示。
        .alert(
            LumiPluginLocalization.string("Rename Failed", bundle: .module),
            isPresented: $isPresentingRenameError
        ) {
            Button(LumiPluginLocalization.string("OK", bundle: .module), role: .cancel) {}
        } message: {
            Text(renameErrorMessage ?? "")
        }
        .alert(
            LumiPluginLocalization.string("Re-clone Project", bundle: .module),
            isPresented: recloneAlertPresented,
            presenting: projectPendingReclone
        ) { project in
            Button(LumiPluginLocalization.string("Re-clone", bundle: .module), role: .destructive) {
                beginReclone(project)
            }
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {}
        } message: { project in
            Text(
                String(
                    format: LumiPluginLocalization.string(
                        "This will delete the local project at \"%@\" and replace it with a fresh clone from \"%@\". Uncommitted changes will be lost.",
                        bundle: .module
                    ),
                    project.url.path,
                    recloneRemoteURL ?? ""
                )
            )
        }
        .alert(
            LumiPluginLocalization.string("Re-clone Failed", bundle: .module),
            isPresented: $isPresentingRecloneError
        ) {
            Button(LumiPluginLocalization.string("OK", bundle: .module), role: .cancel) {}
        } message: {
            Text(recloneErrorMessage ?? "")
        }
    }

    /// 重命名输入框的展示绑定：`projectPendingRename` 非 nil 时弹出。
    private var renameAlertPresented: Binding<Bool> {
        Binding(
            get: { projectPendingRename != nil },
            set: { if !$0 { projectPendingRename = nil } }
        )
    }

    private var recloneAlertPresented: Binding<Bool> {
        Binding(
            get: { projectPendingReclone != nil },
            set: {
                if !$0 {
                    projectPendingReclone = nil
                    recloneRemoteURL = nil
                }
            }
        )
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

            if git != nil, cloneRepository != nil {
                Divider()

                Button(role: .destructive) {
                    prepareReclone(project)
                } label: {
                    Label(
                        LumiPluginLocalization.string("Re-clone Project", bundle: .module),
                        systemImage: "arrow.clockwise"
                    )
                }
                .disabled(recloneTaskID != nil)
            }

            Button {
                renameText = project.title
                projectPendingRename = project
            } label: {
                Label(
                    LumiPluginLocalization.string("Rename Project", bundle: .module),
                    systemImage: "pencil"
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
        .overlay(alignment: .bottom) {
            if isLastPinned {
                AppDivider().padding(.vertical, 2)
            }
        }
    }

    private func moveProject(_ draggedID: UUID, before targetID: UUID?) {
        projects.moveProject(id: draggedID, beforeID: targetID)
    }

    private func prepareReclone(_ project: Project) {
        guard recloneTaskID == nil else { return }
        guard let git else { return }

        let projectURL = project.url.standardizedFileURL
        let homeURL = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        guard projectURL.path != "/", projectURL != homeURL else {
            presentRecloneError("Refusing to replace a system or home directory.")
            return
        }

        let remotes = git.listRemotes(in: projectURL)
        guard let remote = remotes.first(where: { $0.name == "origin" }) ?? remotes.first,
              !(remote.fetchURL ?? remote.url).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            presentRecloneError(
                LumiPluginLocalization.string("No remote repository found.", bundle: .module)
            )
            return
        }
        let remoteURL = remote.fetchURL ?? remote.url

        recloneRemoteURL = remoteURL
        projectPendingReclone = project
    }

    private func beginReclone(_ project: Project) {
        guard let git, let cloneRepository, let remoteURL = recloneRemoteURL else { return }
        projectPendingReclone = nil

        let projectURL = project.url.standardizedFileURL
        let temporaryDestination = projectURL
            .deletingLastPathComponent()
            .appendingPathComponent(".gitok-reclone-\(UUID().uuidString)", isDirectory: true)

        do {
            try git.validateCloneDestination(temporaryDestination)
            let task = try cloneRepository.enqueue(
                remoteURL: remoteURL,
                destination: temporaryDestination,
                repositoryName: project.title
            )
            recloneProject = project
            recloneDestination = temporaryDestination
            recloneTaskID = task.id
        } catch {
            presentRecloneError(error.localizedDescription)
        }
    }

    @MainActor
    private func monitorReclone(taskID: UUID) async {
        while !Task.isCancelled {
            guard recloneTaskID == taskID,
                  let cloneRepository,
                  let task = cloneRepository.tasks.first(where: { $0.id == taskID }) else { return }

            switch task.status {
            case .completed:
                await finishReclone(taskID: taskID)
                return
            case .failed, .cancelled:
                finishFailedReclone(
                    taskID: taskID,
                    message: task.errorMessage
                        ?? LumiPluginLocalization.string("Re-clone Failed", bundle: .module)
                )
                return
            case .queued, .cloning, .cancelling:
                break
            }

            do {
                try await Task.sleep(for: .milliseconds(250))
            } catch {
                return
            }
        }
    }

    @MainActor
    private func finishReclone(taskID: UUID) async {
        guard recloneTaskID == taskID,
              let project = recloneProject,
              let temporaryDestination = recloneDestination else { return }

        let replacementError: String? = await Task.detached(priority: .userInitiated) { () -> String? in
            do {
                try Self.replaceProjectDirectory(
                    with: temporaryDestination,
                    at: project.url.standardizedFileURL
                )
                return nil
            } catch {
                return error.localizedDescription
            }
        }.value

        guard recloneTaskID == taskID else { return }
        if let replacementError {
            finishFailedReclone(taskID: taskID, message: replacementError)
            return
        }

        resetRecloneState()
        projects.notifyDataChanged()
    }

    private func finishFailedReclone(taskID: UUID, message: String) {
        guard recloneTaskID == taskID else { return }
        if let recloneDestination {
            try? FileManager.default.removeItem(at: recloneDestination)
        }
        resetRecloneState()
        presentRecloneError(message)
    }

    private func presentRecloneError(_ message: String) {
        recloneErrorMessage = message
        isPresentingRecloneError = true
    }

    private func resetRecloneState() {
        recloneTaskID = nil
        recloneProject = nil
        recloneDestination = nil
        recloneRemoteURL = nil
        projectPendingReclone = nil
    }

    nonisolated private static func replaceProjectDirectory(with clonedURL: URL, at projectURL: URL) throws {
        let fileManager = FileManager.default
        let parentURL = projectURL.deletingLastPathComponent()
        let backupURL = parentURL
            .appendingPathComponent(".gitok-reclone-backup-\(UUID().uuidString)", isDirectory: true)
        var originalWasMoved = false

        do {
            if fileManager.fileExists(atPath: projectURL.path) {
                try fileManager.moveItem(at: projectURL, to: backupURL)
                originalWasMoved = true
            }
            try fileManager.moveItem(at: clonedURL, to: projectURL)
            if originalWasMoved {
                try fileManager.removeItem(at: backupURL)
            }
        } catch {
            if originalWasMoved {
                if fileManager.fileExists(atPath: projectURL.path) {
                    try? fileManager.removeItem(at: projectURL)
                }
                if fileManager.fileExists(atPath: backupURL.path) {
                    try? fileManager.moveItem(at: backupURL, to: projectURL)
                }
            }
            throw error
        }
    }

    private func copyProjectPath(_ project: Project) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(project.url.path, forType: .string)
    }

    private func openProjectInFinder(_ project: Project) {
        NSWorkspace.shared.activateFileViewerSelecting([project.url])
    }

    /// 执行重命名：调用 `ProjectProviding.renameProject`，失败时展示错误弹窗。
    @MainActor
    private func performRename() {
        guard let project = projectPendingRename else { return }
        do {
            try projects.renameProject(id: project.id, newName: renameText)
        } catch {
            renameErrorMessage = error.localizedDescription
            isPresentingRenameError = true
        }
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

/// 将拖放目标转换为项目 ID 移动操作。
private struct ProjectDropDelegate: DropDelegate {
    let draggedProjectID: UUID?
    let targetProjectID: UUID?
    let onMove: (UUID, UUID?) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedProjectID, draggedProjectID != targetProjectID else { return }
        onMove(draggedProjectID, targetProjectID)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        true
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
