import AppKit
import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 仓库设置视图：当前项目信息 + 远程仓库列表 + 添加远程
/// （对齐旧版 RepositorySettingView）。
public struct RepositorySettingView: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel

    @State private var remotes: [GitRemoteSummary] = []
    @State private var isLoading = false
    @State private var showAddRemoteSheet = false
    @State private var errorMessage: String?

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 16) {
                if let project = projects.currentProject {
                    currentProjectInfo(project: project)
                    if remotes.isEmpty {
                        emptyRemoteRepositoryState
                    } else {
                        remoteRepositoryList
                    }
                    addRemoteRepositoryButton
                } else {
                    noProjectSelected
                }
                if let errorMessage {
                    AppErrorBanner(message: LocalizedStringKey(errorMessage))
                }
            }
        }
        .navigationTitle(Text("Repository Settings"))
        .onAppear(perform: loadData)
        .onReceive(observation.$lastEvent) { event in
            if case .dataChanged = event {
                loadData()
            }
        }
        .sheet(isPresented: $showAddRemoteSheet) {
            AddRemoteRepositorySheet { name, url in
                addRemoteRepository(name: name, url: url)
            }
        }
    }

    // MARK: - Sections

    private func currentProjectInfo(project: Project) -> some View {
        AppSettingSection(title: "Current Project", titleAlignment: .leading) {
            VStack(spacing: 0) {
                repositoryInfoRow(
                    title: "Project Name",
                    description: project.title,
                    icon: "folder"
                )
                Divider()
                repositoryInfoRow(
                    title: "Local Path",
                    description: project.url.path,
                    icon: "line.3.horizontal.decrease.circle"
                ) {
                    AppIconButton(systemImage: "folder", size: .regular) {
                        NSWorkspace.shared.activateFileViewerSelecting([project.url])
                    }
                }
            }
        }
    }

    private var remoteRepositoryList: some View {
        AppSettingSection(title: "Remote Repository", titleAlignment: .leading) {
            VStack(spacing: 0) {
                ForEach(remotes) { remote in
                    remoteRepositoryRow(remote)
                    if remote.id != remotes.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func remoteRepositoryRow(_ remote: GitRemoteSummary) -> some View {
        AppSettingRow(
            title: remote.name,
            description: remote.url,
            icon: "cloud"
        ) {
            HStack(spacing: 4) {
                if let httpsURL = GitRemoteOperation.webLink(for: remote.url) {
                    AppIconButton(systemImage: "safari", size: .regular) {
                        NSWorkspace.shared.open(httpsURL)
                    }
                }
                AppIconButton(systemImage: "doc.on.doc", size: .regular) {
                    copyText(remote.url)
                }
                AppIconButton(systemImage: "trash", tint: theme.warning, size: .regular) {
                    deleteRemoteRepository(remote)
                }
            }
        }
    }

    private var emptyRemoteRepositoryState: some View {
        AppSettingSection(title: "Remote Repository", titleAlignment: .leading) {
            VStack(spacing: 6) {
                Image(systemName: "icloud.slash")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.textTertiary)
                Text("No Remote Repository Configured")
                    .font(.system(size: 13, weight: .medium))
                Text("Add a remote repository to enable push and pull operations")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        }
    }

    private var addRemoteRepositoryButton: some View {
        AppSettingSection(titleAlignment: .leading) {
            AppSettingRow(
                title: "Add Remote Repository",
                description: "Add a new remote repository URL",
                icon: "plus"
            ) {
                EmptyView()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showAddRemoteSheet = true
            }
        }
    }

    private var noProjectSelected: some View {
        AppSettingSection(titleAlignment: .leading) {
            VStack(spacing: 6) {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.textTertiary)
                Text("Please Select a Project First")
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private func repositoryInfoRow<Accessory: View>(
        title: String,
        description: String,
        icon: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        AppSettingRow(title: title, description: description, icon: icon) {
            accessory()
        }
    }

    private func repositoryInfoRow(title: String, description: String, icon: String) -> some View {
        repositoryInfoRow(title: title, description: description, icon: icon) {
            EmptyView()
        }
    }

    // MARK: - Actions

    @MainActor
    private func loadData() {
        guard let url = projects.currentProject?.url else {
            remotes = []
            return
        }
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            let loaded = GitRemoteOperation.listRemotes(in: url)
            await MainActor.run {
                remotes = loaded
                isLoading = false
            }
        }
    }

    @MainActor
    private func addRemoteRepository(name: String, url: String) {
        guard let projectURL = projects.currentProject?.url else {
            errorMessage = "Please Select a Project First"
            return
        }
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                try GitRemoteOperation.addRemote(name: name, url: url, in: projectURL)
                let loaded = GitRemoteOperation.listRemotes(in: projectURL)
                await MainActor.run {
                    remotes = loaded
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to add remote repository: \(error.localizedDescription)"
                }
            }
        }
    }

    @MainActor
    private func deleteRemoteRepository(_ remote: GitRemoteSummary) {
        guard let projectURL = projects.currentProject?.url else { return }
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                try GitRemoteOperation.removeRemote(name: remote.name, in: projectURL)
                let loaded = GitRemoteOperation.listRemotes(in: projectURL)
                await MainActor.run {
                    remotes = loaded
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to delete remote repository: \(error.localizedDescription)"
                }
            }
        }
    }

    private func copyText(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    @LumiTheme private var theme: LumiUITheme
}

/// 添加远程仓库表单。
public struct AddRemoteRepositorySheet: View {
    let onAdd: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var url = ""
    @LumiTheme private var theme

    public init(onAdd: @escaping (String, String) -> Void) {
        self.onAdd = onAdd
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Remote Repository")
                .font(.headline)
            AppInputField("Remote name (e.g. origin)", text: $name)
            AppInputField("Repository URL", text: $url)
            HStack {
                Spacer()
                AppButton("Cancel", style: .secondary, size: .small) {
                    dismiss()
                }
                AppButton(
                    "Add",
                    systemImage: "plus",
                    style: .primary,
                    size: .small
                ) {
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedName.isEmpty, !trimmedURL.isEmpty else { return }
                    onAdd(trimmedName, trimmedURL)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}

/// 项目观察模型：订阅 `ProjectProviding` 事件。
@MainActor
final class ProjectObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    @Published private(set) var lastEvent: ProjectProvidingEvent?
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] event in
            self?.lastEvent = event
            self?.revision += 1
        }
    }
}
