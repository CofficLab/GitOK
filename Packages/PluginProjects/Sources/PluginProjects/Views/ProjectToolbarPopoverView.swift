import ProviderProjects
import SwiftUI

/// 工具栏项目弹层：搜索 + 添加 + 项目列表（Lumi 风格）。
struct ProjectToolbarPopoverView: View {
    let projects: any ProjectProviding
    let requestImporter: () -> Void
    @StateObject private var observation: ProjectObservationModel
    @State private var searchText = ""

    init(projects: any ProjectProviding, requestImporter: @escaping () -> Void) {
        self.projects = projects
        self.requestImporter = requestImporter
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    private var filteredProjects: [Project] {
        let list = projects.projects
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return list }
        let needle = searchText.trimmingCharacters(in: .whitespaces)
        return list.filter { $0.title.localizedCaseInsensitiveContains(needle) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            listContent
        }
        .frame(width: 320)
        .frame(minHeight: 220, maxHeight: 420)
    }

    private var header: some View {
        HStack(spacing: 8) {
            TextField("Search", text: $searchText)
                .textFieldStyle(.roundedBorder)

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

    @ViewBuilder
    private var listContent: some View {
        if filteredProjects.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 2) {
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
            Text(projects.projects.isEmpty ? "No Projects" : "No Results")
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
