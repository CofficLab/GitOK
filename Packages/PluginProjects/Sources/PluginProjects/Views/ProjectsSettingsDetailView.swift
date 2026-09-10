import AppKit
import LumiUI
import ProviderProjects
import SwiftUI

/// 设置窗口「项目」标签页 —— 双栏布局：左侧项目列表，右侧项目详情。
///
/// 从 `ProjectProviding` 读取项目列表，左侧列表面板支持搜索过滤和选中，
/// 右侧详情面板展示选中项目的完整信息（路径、置顶状态、最近打开时间）和操作按钮。
/// 数据变化时通过 `ProjectObservationModel` 触发重算。
struct ProjectsSettingsDetailView: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @LumiUI.LumiTheme private var uiTheme: any LumiUI.LumiUITheme

    @State private var selectedID: UUID?
    @State private var searchText = ""

    init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    // MARK: - Filtered & Selected

    private var filteredProjects: [Project] {
        let list = projects.projects
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return list }
        return list.filter {
            $0.title.localizedCaseInsensitiveContains(keyword)
                || $0.url.path.localizedCaseInsensitiveContains(keyword)
        }
    }

    private var selectedProject: Project? {
        if let selectedID, let project = projects.projects.first(where: { $0.id == selectedID }) {
            return project
        }
        return filteredProjects.first ?? projects.projects.first
    }

    var body: some View {
        AppSettingsContentScaffold(scrollsContent: false, maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 14) {
                headerStats

                HStack(spacing: 0) {
                    projectListPane.frame(width: 300)
                    AppDivider(.vertical)
                    projectDetailPane
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(minHeight: 520, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(uiTheme.divider, lineWidth: 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.bottom, 16)
        .onAppear { selectedID = selectedProject?.id }
        .onReceive(observation.$revision) { _ in
            // 项目数据变化时重算 body，读取最新项目列表
        }
        .onChange(of: filteredProjects.map(\.id)) { _, ids in
            guard let selectedID, ids.contains(selectedID) else {
                self.selectedID = ids.first
                return
            }
        }
    }

    // MARK: - Header Stats

    private var headerStats: some View {
        HStack(spacing: 10) {
            Label(
                String(
                    format: LumiPluginLocalization.string("%lld Projects", bundle: .module),
                    projects.projects.count
                ),
                systemImage: "folder"
            )
            if let current = projects.currentProject {
                Text(
                    String(
                        format: LumiPluginLocalization.string("Current: %@", bundle: .module),
                        current.title
                    )
                )
            }
            Spacer()
            AppButton(
                LumiPluginLocalization.string("Add Project", bundle: .module),
                systemImage: "plus",
                style: .primary,
                size: .small
            ) {
                addProject()
            }
#if DEBUG
            AppButton(
                LumiPluginLocalization.string("Open Data Directory", bundle: .module),
                systemImage: "folder",
                style: .warning,
                size: .small
            ) {
                openDataDirectory()
            }
#endif
        }
        .font(.appCaption)
        .foregroundStyle(uiTheme.textSecondary)
    }

    // MARK: - 左侧项目列表面板

    private var projectListPane: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                AppSearchBar(
                    text: $searchText,
                    placeholder: LocalizedStringKey(LumiPluginLocalization.string("Search Projects", bundle: .module))
                )
            }
            .padding(12)

            AppDivider()

            ScrollView {
                LazyVStack(spacing: 4) {
                    if filteredProjects.isEmpty {
                        if projects.projects.isEmpty {
                            AppEmptyState(
                                icon: "folder.badge.plus",
                                title: LumiPluginLocalization.string("No Projects", bundle: .module)
                            )
                            .padding(.vertical, 32)
                        } else {
                            AppEmptyState(
                                icon: "magnifyingglass",
                                title: LumiPluginLocalization.string("No Results", bundle: .module)
                            )
                            .padding(.vertical, 32)
                        }
                    } else {
                        ForEach(filteredProjects) { project in
                            projectListRow(project)
                        }
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: .infinity)
        }
        .appSurface(style: .panel, cornerRadius: 0)
    }

    private func projectListRow(_ project: Project) -> some View {
        let isSelected = selectedProject?.id == project.id
        let isCurrent = projects.currentProject?.id == project.id
        return AppListRow(isSelected: isSelected, action: {
            withAnimation(.easeInOut(duration: 0.2)) { selectedID = project.id }
        }) {
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 6) {
                    Image(systemName: project.isPinned ? "pin.fill" : "folder")
                        .font(.appBody)
                        .foregroundStyle(project.isPinned ? uiTheme.primary : uiTheme.textSecondary)
                        .frame(width: 22, height: 22)
                    Circle()
                        .fill(isCurrent ? uiTheme.success : uiTheme.textTertiary.opacity(0.45))
                        .frame(width: 6, height: 6)
                }
                .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(project.title)
                        .font(.appCaptionEmphasized)
                        .foregroundStyle(uiTheme.textPrimary)
                        .lineLimit(1)
                    Text(project.url.path)
                        .font(.appMicro)
                        .foregroundStyle(uiTheme.textSecondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - 右侧项目详情面板

    @ViewBuilder
    private var projectDetailPane: some View {
        if let project = selectedProject {
            ProjectPreviewPane(
                project: project,
                isCurrent: projects.currentProject?.id == project.id,
                containerBackground: uiTheme.surface,
                onOpen: { projects.openProject(at: project.url) },
                onOpenInFinder: {
                    NSWorkspace.shared.activateFileViewerSelecting([project.url])
                },
                onTogglePin: {
                    projects.pinProject(id: project.id, isPinned: !project.isPinned)
                },
                onRemove: {
                    projects.removeProject(id: project.id)
                },
                onCopyPath: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(project.url.path, forType: .string)
                }
            )
        } else {
            AppEmptyState(
                icon: "folder",
                title: LumiPluginLocalization.string("Select a Project", bundle: .module)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Actions

    private func addProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = LumiPluginLocalization.string("Choose a project folder to add", bundle: .module)
        panel.prompt = LumiPluginLocalization.string("Add", bundle: .module)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        projects.addProject(at: url)
    }

    // MARK: - Debug Helpers

    #if DEBUG
    private func openDataDirectory() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.coffic.gitok", isDirectory: true)
        guard let url = appSupport else { return }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }
    #endif
}

// MARK: - 项目详情预览面板

private struct ProjectPreviewPane: View {
    let project: Project
    let isCurrent: Bool
    let containerBackground: Color
    let onOpen: () -> Void
    let onOpenInFinder: () -> Void
    let onTogglePin: () -> Void
    let onRemove: () -> Void
    let onCopyPath: () -> Void

    @LumiUI.LumiTheme private var uiTheme: any LumiUI.LumiUITheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                AppDivider()
                infoSection
                AppDivider()
                actionsSection
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(containerBackground)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: project.isPinned ? "pin.fill" : "folder.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(project.isPinned ? uiTheme.primary : uiTheme.textSecondary)
                .frame(width: 64, height: 64)
                .background(
                    (project.isPinned ? uiTheme.primary : uiTheme.textSecondary).opacity(0.14)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(project.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(uiTheme.textPrimary)
                Text(project.url.path)
                    .font(.appCaption)
                    .foregroundStyle(uiTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    if isCurrent {
                        AppTag(
                            LumiPluginLocalization.string("Currently Open", bundle: .module),
                            style: .accent
                        )
                    }
                    if project.isPinned {
                        AppTag(
                            LumiPluginLocalization.string("Pinned", bundle: .module),
                            systemImage: "pin.fill",
                            style: .subtle
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: "info.circle")
                    .font(.appCaptionEmphasized)
                    .foregroundStyle(uiTheme.primary)
                Text(LumiPluginLocalization.string("Project Information", bundle: .module))
                    .font(.appCaptionEmphasized)
                    .foregroundStyle(uiTheme.textPrimary)
            }

            VStack(spacing: 0) {
                infoRow(
                    icon: "folder",
                    title: LumiPluginLocalization.string("Name", bundle: .module),
                    value: project.title
                )
                Divider().padding(.vertical, 8)
                infoRow(
                    icon: "link",
                    title: LumiPluginLocalization.string("Path", bundle: .module),
                    value: project.url.path,
                    monospaced: true
                )
                Divider().padding(.vertical, 8)
                infoRow(
                    icon: "pin",
                    title: LumiPluginLocalization.string("Pinned", bundle: .module),
                    value: project.isPinned
                        ? LumiPluginLocalization.string("Yes", bundle: .module)
                        : LumiPluginLocalization.string("No", bundle: .module)
                )
                if let lastOpened = project.lastOpenedAt {
                    Divider().padding(.vertical, 8)
                    infoRow(
                        icon: "clock",
                        title: LumiPluginLocalization.string("Last Opened", bundle: .module),
                        value: Self.dateFormatter.string(from: lastOpened)
                    )
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(uiTheme.elevatedSurface.opacity(0.72))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(uiTheme.textSecondary.opacity(0.14), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func infoRow(icon: String, title: String, value: String, monospaced: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.appMicro)
                .foregroundStyle(uiTheme.textSecondary)
                .frame(width: 16)
            Text(title)
                .font(.appCaptionEmphasized)
                .foregroundStyle(uiTheme.textPrimary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(monospaced ? .appMicro.monospaced() : .appMicro)
                .foregroundStyle(uiTheme.textSecondary)
                .textSelection(.enabled)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: "lightbulb")
                    .font(.appCaptionEmphasized)
                    .foregroundStyle(uiTheme.primary)
                Text(LumiPluginLocalization.string("Actions", bundle: .module))
                    .font(.appCaptionEmphasized)
                    .foregroundStyle(uiTheme.textPrimary)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 12
            ) {
                actionCard(
                    title: isCurrent
                        ? LumiPluginLocalization.string("Reopen Project", bundle: .module)
                        : LumiPluginLocalization.string("Open Project", bundle: .module),
                    systemImage: "arrow.up.forward.app",
                    color: uiTheme.success
                ) {
                    onOpen()
                }
                actionCard(
                    title: LumiPluginLocalization.string("Open in Finder", bundle: .module),
                    systemImage: "folder",
                    color: uiTheme.info
                ) {
                    onOpenInFinder()
                }
                actionCard(
                    title: project.isPinned
                        ? LumiPluginLocalization.string("Unpin", bundle: .module)
                        : LumiPluginLocalization.string("Pin to Top", bundle: .module),
                    systemImage: project.isPinned ? "pin.slash" : "pin",
                    color: uiTheme.warning
                ) {
                    onTogglePin()
                }
                actionCard(
                    title: LumiPluginLocalization.string("Copy Path", bundle: .module),
                    systemImage: "doc.on.doc",
                    color: uiTheme.textSecondary
                ) {
                    onCopyPath()
                }
            }

            AppDivider().padding(.vertical, 4)

            AppButton(
                LumiPluginLocalization.string("Remove Project", bundle: .module),
                systemImage: "trash",
                style: .destructive,
                size: .small,
                action: onRemove
            )
        }
    }

    private func actionCard(title: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.appBody)
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text(title)
                    .font(.appCaptionEmphasized)
                    .foregroundStyle(uiTheme.textPrimary)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(uiTheme.elevatedSurface.opacity(0.72))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(uiTheme.textSecondary.opacity(0.14), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.doesRelativeDateFormatting = true
        return f
    }()
}
