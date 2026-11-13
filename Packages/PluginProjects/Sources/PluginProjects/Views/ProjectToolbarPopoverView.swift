import ProviderProjects
import SwiftUI

/// 工具栏项目弹层：搜索 + 添加 + 项目列表（Lumi 风格）。
struct ProjectToolbarPopoverView: View {
    let projects: any ProjectSidebarCapability
    let requestImporter: () -> Void
    @StateObject private var observation: ProjectObservationModel
    @State private var searchText = ""

    /// 搜索防抖：连续输入只在停顿后过滤一次，避免每个字符都全量过滤。
    @State private var debounceTask: Task<Void, Never>?

    /// 已生效的搜索词（防抖后的结果）。
    @State private var appliedSearchText = ""

    init(projects: any ProjectSidebarCapability, requestImporter: @escaping () -> Void) {
        self.projects = projects
        self.requestImporter = requestImporter
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    /// 过滤后的项目列表。
    ///
    /// 结果缓存在 `appliedSearchText` 对应的状态里：只有搜索词真正变化
    /// 才会重新过滤，视图的其它重算不会重复遍历全量项目。
    private var filteredProjects: [Project] {
        let needle = appliedSearchText.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return projects.projects }
        return projects.projects.filter { $0.title.localizedCaseInsensitiveContains(needle) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            listContent
        }
        .frame(width: 320)
        .frame(minHeight: 220, maxHeight: 420)
        .onDisappear {
            debounceTask?.cancel()
            debounceTask = nil
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            TextField(pluginLocalization.string("Search"), text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: searchText) { _, newValue in
                    scheduleSearch(newValue)
                }

            Button {
                requestImporter()
            } label: {
                Image(systemName: "folder.badge.plus")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// 防抖应用搜索词。
    private func scheduleSearch(_ text: String) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            appliedSearchText = text
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if filteredProjects.isEmpty {
            emptyState
        } else {
            ScrollView {
                // 懒加载：项目很多时只构建可见行的视图，而不是一次铺满全部。
                LazyVStack(spacing: 2) {
                    ForEach(filteredProjects) { project in
                        row(for: project)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 300)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: projects.projects.isEmpty ? "folder.badge.plus" : "magnifyingglass")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text(projects.projects.isEmpty ? pluginLocalization.string("No Projects") : pluginLocalization.string("No Results"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func row(for project: Project) -> some View {
        let isSelected = projects.currentProject?.id == project.id
        return Button {
            projects.setCurrentProject(id: project.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(project.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
