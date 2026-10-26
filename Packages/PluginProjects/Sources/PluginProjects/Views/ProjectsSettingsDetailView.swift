import AppKit
import LumiUI
import ProviderProjects
import SwiftUI

/// 设置窗口「项目」标签页 —— 双栏布局：左侧项目列表，右侧项目详情。
///
/// 布局与 Lumi 的「项目」设置页一致（贴边分栏 + 原生 `AppSettingSection` 卡片）：
/// - 主体内容贴到窗口左右与底边，没有外框描边，也没有底部留白；
/// - 头部行自行保留 24 的左右内边距，与主体之间用一条 `AppDivider()` 分开；
/// - 左侧列表栏固定 300 宽，右侧详情栏内容内边距 22；
/// - 主从容器只写 `.frame(maxHeight: .infinity)`，不写死下限，避免整页超出
///   窗口后被居中裁切（顶部与底部同时被切掉）。
///
/// 数据从 `ProjectProviding` 读取，左侧列表面板支持搜索过滤和选中，
/// 右侧详情面板展示选中项目的完整信息（路径、置顶状态、最近打开时间）和操作按钮。
/// 数据变化时通过 `ProjectObservationModel` 触发重算。
struct ProjectsSettingsDetailView: View {
    let projects: any ProjectSidebarCapability
    @StateObject private var observation: ProjectObservationModel
    @LumiUI.LumiTheme private var uiTheme: any LumiUI.LumiUITheme

    @State private var selectedID: UUID?
    @State private var searchText = ""

    init(projects: any ProjectSidebarCapability) {
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
            GeometryReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)

                    // 主体内容贴边后，用一条顶部分隔线把头部行与主从容器分开。
                    AppDivider()

                    HStack(spacing: 0) {
                        projectListPane
                            .frame(width: 300)
                            .frame(maxHeight: .infinity)

                        AppDivider(.vertical)

                        projectDetailPane
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                    .frame(maxHeight: .infinity)
                }
                // 共享 scaffold 给内容留了左右 24，这里把整列加宽 48 并左移 24，
                // 使主从容器正好贴到窗口左右边缘；标题行再自行补回 24 留白。
                .frame(width: proxy.size.width + 48, alignment: .topLeading)
                .offset(x: -24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .environment(\.appSettingsCardStyleOverride, .subtle)
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

    // MARK: - Header

    /// 头部行：项目数量 + 当前项目 + 添加项目按钮。
    ///
    /// 头部内容自行保留 24 的左右内边距，不贴到窗口边缘。
    private var header: some View {
        HStack(spacing: 10) {
            Label(
                String(
                    format: pluginLocalization.string("%lld Projects"),
                    projects.projects.count
                ),
                systemImage: "folder"
            )
            if let current = projects.currentProject {
                Text("·")
                Text(current.title)
            }
            Spacer()
            AppButton(
                pluginLocalization.string("Add Project"),
                systemImage: "plus",
                style: .secondary,
                size: .small
            ) {
                addProject()
            }
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
                    placeholder: LocalizedStringKey(pluginLocalization.string("Search Projects"))
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
                                title: pluginLocalization.string("No Projects")
                            )
                            .padding(.vertical, 32)
                        } else {
                            AppEmptyState(
                                icon: "magnifyingglass",
                                title: pluginLocalization.string("No Results")
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
            HStack(spacing: 10) {
                Image(systemName: project.isPinned ? "pin.fill" : "folder")
                    .font(.appCaptionEmphasized)
                    .foregroundStyle(isSelected ? uiTheme.primary : uiTheme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(
                        Color.primary.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 6)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(project.title)
                            .font(.appCaptionEmphasized)
                            .lineLimit(1)
                        if isCurrent {
                            Text(pluginLocalization.string("Current"))
                                .font(.appMicroEmphasized)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(uiTheme.primary, in: Capsule())
                        }
                    }
                    Text(project.url.path)
                        .font(.appMicro)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - 右侧项目详情面板

    @ViewBuilder
    private var projectDetailPane: some View {
        if let project = selectedProject {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    overviewSection(project)
                    infoSection(project)
                    actionsSection(project)
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appSurface(style: .panel, cornerRadius: 0)
        } else {
            AppEmptyState(
                icon: "folder",
                title: pluginLocalization.string("Select a Project")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appSurface(style: .panel, cornerRadius: 0)
        }
    }

    // MARK: - 概览

    /// 概览卡片：项目图标、名称、路径与状态标签。
    private func overviewSection(_ project: Project) -> some View {
        AppSettingSection(
            title: pluginLocalization.string("Overview"),
            titleAlignment: .leading
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: project.isPinned ? "pin.fill" : "folder.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(project.isPinned ? uiTheme.primary : uiTheme.textSecondary)
                        .frame(width: 64, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(uiTheme.appAccentSoftFill)
                        )

                    VStack(alignment: .leading, spacing: 7) {
                        Text(project.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(uiTheme.textPrimary)
                            .lineLimit(2)
                        Text(project.url.path)
                            .font(.callout)
                            .foregroundStyle(uiTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 6) {
                    if projects.currentProject?.id == project.id {
                        AppTag(
                            pluginLocalization.string("Currently Open"),
                            style: .accent
                        )
                    }
                    if project.isPinned {
                        AppTag(
                            pluginLocalization.string("Pinned"),
                            systemImage: "pin.fill",
                            style: .subtle
                        )
                    }
                }
            }
        }
    }

    // MARK: - 基本信息

    /// 基本信息卡片：名称 / 路径 / 置顶状态 / 最近打开时间。
    private func infoSection(_ project: Project) -> some View {
        AppSettingSection(
            title: pluginLocalization.string("Project Information"),
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                infoRow(
                    icon: "text.cursor",
                    title: pluginLocalization.string("Name"),
                    value: project.title
                )
                Divider().padding(.vertical, 8)
                infoRow(
                    icon: "folder",
                    title: pluginLocalization.string("Path"),
                    value: project.url.path,
                    monospaced: true
                )
                Divider().padding(.vertical, 8)
                infoRow(
                    icon: "pin",
                    title: pluginLocalization.string("Pinned"),
                    value: project.isPinned
                        ? pluginLocalization.string("Yes")
                        : pluginLocalization.string("No")
                )
                if let lastOpened = project.lastOpenedAt {
                    Divider().padding(.vertical, 8)
                    infoRow(
                        icon: "calendar",
                        title: pluginLocalization.string("Last Opened"),
                        value: Self.dateFormatter.string(from: lastOpened)
                    )
                }
            }
        }
    }

    private func infoRow(icon: String, title: String, value: String, monospaced: Bool = false) -> some View {
        AppSettingRow(title: title, icon: icon) {
            Text(value)
                .font(monospaced ? .system(.callout, design: .monospaced) : .callout)
                .foregroundStyle(uiTheme.textSecondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
                .textSelection(.enabled)
        }
    }

    // MARK: - 操作

    /// 操作卡片：打开 / 在 Finder 中显示 / 置顶 / 复制路径 / 移除。
    private func actionsSection(_ project: Project) -> some View {
        AppSettingSection(
            title: pluginLocalization.string("Actions"),
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                actionRow(
                    icon: "arrow.up.forward.app",
                    title: projects.currentProject?.id == project.id
                        ? pluginLocalization.string("Reopen Project")
                        : pluginLocalization.string("Open Project"),
                    buttonTitle: pluginLocalization.string("Open"),
                    style: .primary
                ) {
                    projects.openProject(at: project.url)
                }
                Divider().padding(.vertical, 8)
                actionRow(
                    icon: "folder",
                    title: pluginLocalization.string("Open in Finder"),
                    buttonTitle: pluginLocalization.string("Open in Finder")
                ) {
                    NSWorkspace.shared.activateFileViewerSelecting([project.url])
                }
                Divider().padding(.vertical, 8)
                actionRow(
                    icon: project.isPinned ? "pin.slash" : "pin",
                    title: project.isPinned
                        ? pluginLocalization.string("Unpin")
                        : pluginLocalization.string("Pin to Top"),
                    buttonTitle: project.isPinned
                        ? pluginLocalization.string("Unpin")
                        : pluginLocalization.string("Pin to Top")
                ) {
                    projects.pinProject(id: project.id, isPinned: !project.isPinned)
                }
                Divider().padding(.vertical, 8)
                actionRow(
                    icon: "doc.on.doc",
                    title: pluginLocalization.string("Copy Path"),
                    buttonTitle: pluginLocalization.string("Copy Path")
                ) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(project.url.path, forType: .string)
                }
                Divider().padding(.vertical, 8)
                actionRow(
                    icon: "trash",
                    title: pluginLocalization.string("Remove Project"),
                    buttonTitle: pluginLocalization.string("Remove Project"),
                    style: .destructive
                ) {
                    projects.removeProject(id: project.id)
                }
#if DEBUG
                Divider().padding(.vertical, 8)
                actionRow(
                    icon: "folder.badge.gearshape",
                    title: pluginLocalization.string("Open Data Directory"),
                    buttonTitle: pluginLocalization.string("Open Data Directory")
                ) {
                    openDataDirectory()
                }
#endif
            }
        }
    }

    /// 操作行：左侧图标 + 标题，右侧按钮。
    private func actionRow(
        icon: String,
        title: String,
        buttonTitle: String,
        style: AppButton.Style = .secondary,
        action: @escaping () -> Void
    ) -> some View {
        AppSettingRow(title: title, icon: icon) {
            AppButton(buttonTitle, style: style, size: .small, action: action)
        }
    }

    // MARK: - Actions

    private func addProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = pluginLocalization.string("Choose a project folder to add")
        panel.prompt = pluginLocalization.string("Add")
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

    // MARK: - Helpers

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.doesRelativeDateFormatting = true
        return f
    }()
}
