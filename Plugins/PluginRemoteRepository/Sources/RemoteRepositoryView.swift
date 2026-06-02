import AppKit
import GitCoreKit
import GitOKCoreKit
import SwiftUI

public struct RemoteRepositoryView: View {
    let projectURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var remotes: [GitRemoteSummary] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddRemoteSheet = false
    @State private var selectedRemote: GitRemoteSummary?
    @State private var editingRemote: GitRemoteSummary?
    @State private var aheadBehind: GitAheadBehind = .noUpstream
    @State private var currentUpstreamRemoteName: String?
    @State private var postRemoteActionMessage: String?
    @State private var isPublishingCurrentBranch = false

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 700, height: 500)
        .sheet(isPresented: $showAddRemoteSheet) {
            AddRemoteSheet { name, url in
                addRemote(name: name, url: url)
            }
        }
        .sheet(item: $editingRemote) { remote in
            EditRemoteSheet(remote: remote) { name, url in
                updateRemote(originalName: remote.name, newName: name, newURL: url)
            }
        }
        .onAppear(perform: loadRemotes)
        .disabled(isLoading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(PluginRemoteRepositoryLocalization.string("Remote Repository Management"))
                    .font(.title2)
                    .fontWeight(.medium)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(PluginRemoteRepositoryLocalization.string("Close"))
            }

            Text(PluginRemoteRepositoryLocalization.string("Manage Git remote repository configuration for the current project"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
    }

    private var content: some View {
        VStack(spacing: 20) {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(PluginRemoteRepositoryLocalization.string("Loading..."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if remotes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "externaldrive.badge.wifi")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)

                        Text(PluginRemoteRepositoryLocalization.string("No Remote Repositories"))
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(PluginRemoteRepositoryLocalization.string("Click the button below to add your first remote repository"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(remotes) { remote in
                                RemoteRepositoryRowView(
                                    remote: remote,
                                    selectedRemote: selectedRemote,
                                    isCurrentUpstreamRemote: remote.name == currentUpstreamRemoteName,
                                    onSelect: { selectedRemote = $0 },
                                    onEdit: { editingRemote = $0 },
                                    onDelete: deleteRemote
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let errorMessage {
                messageView(systemImage: "exclamationmark.triangle", color: .orange, message: errorMessage) {
                    self.errorMessage = nil
                }
            }

            if let postRemoteActionMessage {
                VStack(alignment: .leading, spacing: 8) {
                    messageView(systemImage: "arrow.up.circle", color: .blue, message: postRemoteActionMessage) {
                        self.postRemoteActionMessage = nil
                    }

                    if canPublishCurrentBranch {
                        publishButton(prominent: true)
                    }
                }
            }
        }
        .padding()
    }

    private var footer: some View {
        HStack {
            Button(PluginRemoteRepositoryLocalization.string("Add Remote Repository")) {
                showAddRemoteSheet = true
            }
            .buttonStyle(.borderedProminent)

            if canPublishCurrentBranch {
                publishButton(prominent: false)
            }

            Spacer()

            Button(PluginRemoteRepositoryLocalization.string("Close")) {
                dismiss()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }

    private func messageView(systemImage: String, color: Color, message: String, onClear: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(color)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
            Spacer()
            Button(PluginRemoteRepositoryLocalization.string("Clear"), action: onClear)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func publishButton(prominent: Bool) -> some View {
        if prominent {
            publishButtonContent
                .buttonStyle(.borderedProminent)
        } else {
            publishButtonContent
                .buttonStyle(.bordered)
        }
    }

    private var publishButtonContent: some View {
        Button {
            publishCurrentBranch()
        } label: {
            if isPublishingCurrentBranch {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text(PluginRemoteRepositoryLocalization.string("Publish Current Branch"))
            }
        }
        .controlSize(.small)
        .disabled(isPublishingCurrentBranch)
    }
}

private extension RemoteRepositoryView {
    var repository: GitRepositoryCLI {
        GitRepositoryCLI(repositoryURL: projectURL)
    }

    var canPublishCurrentBranch: Bool {
        remotes.isEmpty == false && aheadBehind.hasUpstream == false
    }

    var preferredPublishRemote: GitRemoteSummary? {
        selectedRemote ?? remotes.first(where: { $0.name == "origin" }) ?? remotes.first
    }

    func loadRemotes() {
        isLoading = true
        errorMessage = nil

        do {
            remotes = try repository.remotes()
            loadRemoteTrackingState()
        } catch {
            errorMessage = String(format: PluginRemoteRepositoryLocalization.string("Failed to load remote repositories: %@"), error.localizedDescription)
        }

        isLoading = false
    }

    func addRemote(name: String, url: String) {
        isLoading = true
        errorMessage = nil

        do {
            try repository.addRemote(name: name, url: url)
            loadRemotes()
            postRemoteActionMessage = firstPushMessage(for: name)
        } catch {
            errorMessage = String(format: PluginRemoteRepositoryLocalization.string("Failed to add remote repository: %@"), error.localizedDescription)
        }

        isLoading = false
    }

    func updateRemote(originalName: String, newName: String, newURL: String) {
        isLoading = true
        errorMessage = nil

        do {
            try repository.updateRemote(originalName: originalName, newName: newName, newURL: newURL)
            loadRemotes()
            postRemoteActionMessage = String(format: PluginRemoteRepositoryLocalization.string("Updated remote repository %@. If the branch has no upstream yet, publish the branch or do the first push."), newName)
        } catch {
            errorMessage = String(format: PluginRemoteRepositoryLocalization.string("Failed to update remote repository: %@"), error.localizedDescription)
        }

        isLoading = false
    }

    func deleteRemote(_ remote: GitRemoteSummary) {
        isLoading = true
        errorMessage = nil

        do {
            let wasUpstreamRemote = remote.name == currentUpstreamRemoteName
            try repository.removeRemote(name: remote.name)
            loadRemotes()
            postRemoteActionMessage = wasUpstreamRemote
                ? String(format: PluginRemoteRepositoryLocalization.string("Deleted the current upstream remote %@. Re-set upstream before push/pull."), remote.name)
                : String(format: PluginRemoteRepositoryLocalization.string("Deleted remote repository %@."), remote.name)

            if selectedRemote?.id == remote.id {
                selectedRemote = nil
            }
        } catch {
            errorMessage = String(format: PluginRemoteRepositoryLocalization.string("Failed to delete remote repository: %@"), error.localizedDescription)
        }

        isLoading = false
    }

    func publishCurrentBranch() {
        guard let remote = preferredPublishRemote else {
            errorMessage = PluginRemoteRepositoryLocalization.string("Please add a remote repository first")
            return
        }

        isPublishingCurrentBranch = true
        errorMessage = nil

        Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                guard let branch = try repository.currentBranchName() else {
                    throw NSError(
                        domain: "GitOK.RemoteRepository",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: PluginRemoteRepositoryLocalization.string("Current repository has no publishable branch")]
                    )
                }

                try repository.publishBranch(localBranch: branch, remote: remote.name)

                await MainActor.run {
                    isPublishingCurrentBranch = false
                    postRemoteActionMessage = String(format: PluginRemoteRepositoryLocalization.string("Published current branch %@, and set upstream to %@/%@."), branch, remote.name, branch)
                    loadRemotes()
                }
            } catch {
                await MainActor.run {
                    isPublishingCurrentBranch = false
                    errorMessage = String(format: PluginRemoteRepositoryLocalization.string("Failed to publish current branch: %@"), error.localizedDescription)
                }
            }
        }
    }

    func loadRemoteTrackingState() {
        do {
            aheadBehind = try repository.aheadBehind()
            currentUpstreamRemoteName = try repository.currentUpstreamRemoteName()
        } catch {
            aheadBehind = .noUpstream
            currentUpstreamRemoteName = nil
        }
    }

    func firstPushMessage(for remoteName: String) -> String {
        if aheadBehind.hasUpstream {
            return String(format: PluginRemoteRepositoryLocalization.string("Added remote repository %@. The current branch already has an upstream."), remoteName)
        }

        return String(format: PluginRemoteRepositoryLocalization.string("Added remote repository %@. The current branch has no upstream yet. For the first push, publish the branch or run git push -u %@ <branch>."), remoteName, remoteName)
    }
}
