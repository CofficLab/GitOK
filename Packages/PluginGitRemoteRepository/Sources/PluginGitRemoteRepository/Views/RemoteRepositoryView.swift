import AppKit
import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 远程仓库状态按钮：network 图标，点击打开远程管理面板
/// （对齐旧版 RemoteRepositoryStatusButton）。
public struct RemoteRepositoryStatusButton: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var isPresented = false

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                Image(systemName: "network")
                    .font(.system(size: 10))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isPresented = true
                    }
                    .help("Manage Remote Repositories")
                    .sheet(isPresented: $isPresented) {
                        RemoteRepositoryView(projects: projects)
                            .frame(minWidth: 520, minHeight: 420)
                    }
            }
        }
        .onReceive(observation.$revision) { _ in }
    }
}

/// 远程仓库管理面板：列出远程 + 添加/删除。
public struct RemoteRepositoryView: View {
    let projects: any ProjectProviding
    @Environment(\.dismiss) private var dismiss

    @State private var remotes: [GitRemoteSummary] = []
    @State private var isLoading = true
    @State private var showAddRemote = false
    @State private var errorMessage: String?

    public init(projects: any ProjectProviding) {
        self.projects = projects
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Remote Repositories")
                    .font(.headline)
                Spacer()
                AppButton("Add", systemImage: "plus", style: .secondary, size: .small) {
                    showAddRemote = true
                }
                AppButton("Close", style: .secondary, size: .small) {
                    dismiss()
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(theme.warning)
            }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if remotes.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "network")
                                .font(.system(size: 22))
                                .foregroundStyle(theme.textTertiary)
                            Text("No remote repository configured")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        ForEach(remotes) { remote in
                            remoteRow(remote)
                        }
                    }
                }
            }
        }
        .padding(16)
        .onAppear(perform: load)
        .sheet(isPresented: $showAddRemote) {
            AddRemoteForm { name, url in
                addRemote(name: name, url: url)
            }
        }
    }

    private func remoteRow(_ remote: GitRemoteSummary) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "cloud")
                .foregroundStyle(theme.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(remote.name)
                    .font(.system(size: 13, weight: .medium))
                Text(remote.url)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            if let webURL = GitRemoteOperation.webLink(for: remote.url) {
                AppIconButton(systemImage: "safari", label: "Open in Browser", tint: theme.textSecondary) {
                    NSWorkspace.shared.open(webURL)
                }
            }
            AppIconButton(systemImage: "doc.on.doc", label: "Copy URL", tint: theme.textSecondary) {
                copyText(remote.url)
            }
            AppIconButton(systemImage: "trash", label: "Delete", tint: theme.warning) {
                deleteRemote(remote)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    @MainActor
    private func load() {
        guard let url = projects.currentProject?.url else {
            remotes = []
            isLoading = false
            return
        }
        isLoading = true
        Task.detached(priority: .userInitiated) {
            let loaded = GitRemoteOperation.listRemotes(in: url)
            await MainActor.run {
                remotes = loaded
                isLoading = false
            }
        }
    }

    @MainActor
    private func addRemote(name: String, url: String) {
        guard let projectURL = projects.currentProject?.url else { return }
        Task.detached(priority: .userInitiated) {
            do {
                try GitRemoteOperation.addRemote(name: name, url: url, in: projectURL)
                let loaded = GitRemoteOperation.listRemotes(in: projectURL)
                await MainActor.run {
                    remotes = loaded
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    @MainActor
    private func deleteRemote(_ remote: GitRemoteSummary) {
        guard let projectURL = projects.currentProject?.url else { return }
        Task.detached(priority: .userInitiated) {
            do {
                try GitRemoteOperation.removeRemote(name: remote.name, in: projectURL)
                let loaded = GitRemoteOperation.listRemotes(in: projectURL)
                await MainActor.run {
                    remotes = loaded
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
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

/// 添加远程仓库小表单。
private struct AddRemoteForm: View {
    let onAdd: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = "origin"
    @State private var url = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Remote Repository")
                .font(.headline)
            AppInputField("Remote name (e.g. origin)", text: $name)
            AppInputField("Repository URL", text: $url)
            HStack {
                Spacer()
                AppButton("Cancel", style: .secondary, size: .small) {
                    dismiss()
                }
                AppButton("Add", systemImage: "plus", style: .primary, size: .small) {
                    onAdd(
                        name.trimmingCharacters(in: .whitespacesAndNewlines),
                        url.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    dismiss()
                }
                .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
