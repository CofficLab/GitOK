import AppKit
import GitCoreKit
import GitOKCoreKit
import GitOKUI
import SwiftUI

private enum RemoteRepositoryBackgroundRunner {
    static func loadRemoteState(projectURL: URL) throws -> (remotes: [GitRemoteSummary], aheadBehind: GitAheadBehind, currentUpstreamRemoteName: String?) {
        let repository = GitRepositoryCLI(repositoryURL: projectURL)
        let remotes = try repository.remotes()
        let aheadBehind = (try? repository.aheadBehind()) ?? .noUpstream
        let currentUpstreamRemoteName = try? repository.currentUpstreamRemoteName()
        return (remotes, aheadBehind, currentUpstreamRemoteName)
    }

    static func runRemoteAction(
        projectURL: URL,
        action: @escaping @Sendable (GitRepositoryCLI) throws -> Void
    ) throws {
        try action(GitRepositoryCLI(repositoryURL: projectURL))
    }

    static func addFirstPushMessage(remoteName: String, aheadBehind: GitAheadBehind) -> String {
        if aheadBehind.hasUpstream {
            return String(format: GitRemoteRepositoryPluginLocalization.string("Added remote repository %@. The current branch already has an upstream."), remoteName)
        }

        return String(format: GitRemoteRepositoryPluginLocalization.string("Added remote repository %@. The current branch has no upstream yet. For the first push, publish the branch or run git push -u %@ <branch>."), remoteName, remoteName)
    }
}

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
                Text(GitRemoteRepositoryPluginLocalization.string("Remote Repository Management"))
                    .font(.title2)
                    .fontWeight(.medium)

                Spacer()

                AppIconButton(systemImage: "xmark.circle.fill", tint: .secondary, size: .regular) {
                    dismiss()
                }
                .help(GitRemoteRepositoryPluginLocalization.string("Close"))
            }

            Text(GitRemoteRepositoryPluginLocalization.string("Manage Git remote repository configuration for the current project"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .gitOKUISurface(style: .toolbar, cornerRadius: 0)
    }

    private var content: some View {
        VStack(spacing: 20) {
            Group {
                if isLoading {
                    AppLoadingOverlay(
                        message: GitRemoteRepositoryPluginLocalization.string("Loading..."),
                        size: .small
                    )
                } else if remotes.isEmpty {
                    AppEmptyState(
                        icon: "externaldrive.badge.wifi",
                        title: GitRemoteRepositoryPluginLocalization.string("No Remote Repositories"),
                        description: GitRemoteRepositoryPluginLocalization.string("Click the button below to add your first remote repository")
                    )
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
                AppErrorBanner(
                    message: errorMessage,
                    retryTitle: GitRemoteRepositoryPluginLocalization.string("Clear")
                ) {
                    self.errorMessage = nil
                }
            }

            if let postRemoteActionMessage {
                VStack(alignment: .leading, spacing: 8) {
                    AppSettingsRow {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.up.circle")
                                .foregroundStyle(.blue)
                            Text(postRemoteActionMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                            Spacer()
                            AppButton(GitRemoteRepositoryPluginLocalization.string("Clear"), style: .ghost, size: .small) {
                                self.postRemoteActionMessage = nil
                            }
                        }
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
            AppButton(
                GitRemoteRepositoryPluginLocalization.string("Add Remote Repository"),
                systemImage: "plus",
                style: .primary
            ) {
                showAddRemoteSheet = true
            }

            if canPublishCurrentBranch {
                publishButton(prominent: false)
            }

            Spacer()

            AppButton(GitRemoteRepositoryPluginLocalization.string("Close"), style: .secondary) {
                dismiss()
            }
            .keyboardShortcut(.escape)
        }
        .padding()
        .gitOKUISurface(style: .toolbar, cornerRadius: 0)
    }

    @ViewBuilder
    private func publishButton(prominent: Bool) -> some View {
        AppButton(
            GitRemoteRepositoryPluginLocalization.string("Publish Current Branch"),
            systemImage: "arrow.up.circle",
            style: prominent ? .primary : .secondary,
            size: .small,
            isLoading: isPublishingCurrentBranch
        ) {
            publishCurrentBranch()
        }
        .disabled(isPublishingCurrentBranch)
    }
}

private extension RemoteRepositoryView {
    var canPublishCurrentBranch: Bool {
        remotes.isEmpty == false && aheadBehind.hasUpstream == false
    }

    var preferredPublishRemote: GitRemoteSummary? {
        selectedRemote ?? remotes.first(where: { $0.name == "origin" }) ?? remotes.first
    }

    func loadRemotes() {
        isLoading = true
        errorMessage = nil
        let projectURL = projectURL

        Task.detached(priority: .userInitiated) {
            do {
                let state = try RemoteRepositoryBackgroundRunner.loadRemoteState(projectURL: projectURL)
                await MainActor.run {
                    remotes = state.remotes
                    aheadBehind = state.aheadBehind
                    currentUpstreamRemoteName = state.currentUpstreamRemoteName
                    isLoading = false
                }
            } catch {
                let message = String(format: GitRemoteRepositoryPluginLocalization.string("Failed to load remote repositories: %@"), error.localizedDescription)
                await MainActor.run {
                    errorMessage = message
                    isLoading = false
                }
            }
        }
    }

    func addRemote(name: String, url: String) {
        isLoading = true
        errorMessage = nil
        let projectURL = projectURL

        Task.detached(priority: .userInitiated) {
            do {
                try RemoteRepositoryBackgroundRunner.runRemoteAction(projectURL: projectURL) { repository in
                    try repository.addRemote(name: name, url: url)
                }
                let state = try RemoteRepositoryBackgroundRunner.loadRemoteState(projectURL: projectURL)
                let actionMessage = RemoteRepositoryBackgroundRunner.addFirstPushMessage(remoteName: name, aheadBehind: state.aheadBehind)
                await MainActor.run {
                    remotes = state.remotes
                    aheadBehind = state.aheadBehind
                    currentUpstreamRemoteName = state.currentUpstreamRemoteName
                    postRemoteActionMessage = actionMessage
                    isLoading = false
                }
            } catch {
                let message = String(format: GitRemoteRepositoryPluginLocalization.string("Failed to add remote repository: %@"), error.localizedDescription)
                await MainActor.run {
                    errorMessage = message
                    isLoading = false
                }
            }
        }
    }

    func updateRemote(originalName: String, newName: String, newURL: String) {
        isLoading = true
        errorMessage = nil
        let projectURL = projectURL

        Task.detached(priority: .userInitiated) {
            do {
                try RemoteRepositoryBackgroundRunner.runRemoteAction(projectURL: projectURL) { repository in
                    try repository.updateRemote(originalName: originalName, newName: newName, newURL: newURL)
                }
                let state = try RemoteRepositoryBackgroundRunner.loadRemoteState(projectURL: projectURL)
                let actionMessage = String(format: GitRemoteRepositoryPluginLocalization.string("Updated remote repository %@. If the branch has no upstream yet, publish the branch or do the first push."), newName)
                await MainActor.run {
                    remotes = state.remotes
                    aheadBehind = state.aheadBehind
                    currentUpstreamRemoteName = state.currentUpstreamRemoteName
                    postRemoteActionMessage = actionMessage
                    isLoading = false
                }
            } catch {
                let message = String(format: GitRemoteRepositoryPluginLocalization.string("Failed to update remote repository: %@"), error.localizedDescription)
                await MainActor.run {
                    errorMessage = message
                    isLoading = false
                }
            }
        }
    }

    func deleteRemote(_ remote: GitRemoteSummary) {
        isLoading = true
        errorMessage = nil
        let remoteName = remote.name
        let remoteID = remote.id
        let wasUpstreamRemote = remoteName == currentUpstreamRemoteName
        let projectURL = projectURL

        Task.detached(priority: .userInitiated) {
            do {
                try RemoteRepositoryBackgroundRunner.runRemoteAction(projectURL: projectURL) { repository in
                    try repository.removeRemote(name: remoteName)
                }
                let state = try RemoteRepositoryBackgroundRunner.loadRemoteState(projectURL: projectURL)
                let actionMessage = wasUpstreamRemote
                    ? String(format: GitRemoteRepositoryPluginLocalization.string("Deleted the current upstream remote %@. Re-set upstream before push/pull."), remoteName)
                    : String(format: GitRemoteRepositoryPluginLocalization.string("Deleted remote repository %@."), remoteName)

                await MainActor.run {
                    remotes = state.remotes
                    aheadBehind = state.aheadBehind
                    currentUpstreamRemoteName = state.currentUpstreamRemoteName
                    postRemoteActionMessage = actionMessage

                    if selectedRemote?.id == remoteID {
                        selectedRemote = nil
                    }
                    isLoading = false
                }
            } catch {
                let message = String(format: GitRemoteRepositoryPluginLocalization.string("Failed to delete remote repository: %@"), error.localizedDescription)
                await MainActor.run {
                    errorMessage = message
                    isLoading = false
                }
            }
        }
    }

    func publishCurrentBranch() {
        guard let remote = preferredPublishRemote else {
            errorMessage = GitRemoteRepositoryPluginLocalization.string("Please add a remote repository first")
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
                        userInfo: [NSLocalizedDescriptionKey: GitRemoteRepositoryPluginLocalization.string("Current repository has no publishable branch")]
                    )
                }

                try repository.publishBranch(localBranch: branch, remote: remote.name)

                await MainActor.run {
                    isPublishingCurrentBranch = false
                    postRemoteActionMessage = String(format: GitRemoteRepositoryPluginLocalization.string("Published current branch %@, and set upstream to %@/%@."), branch, remote.name, branch)
                    loadRemotes()
                }
            } catch {
                await MainActor.run {
                    isPublishingCurrentBranch = false
                    errorMessage = String(format: GitRemoteRepositoryPluginLocalization.string("Failed to publish current branch: %@"), error.localizedDescription)
                }
            }
        }
    }

    func loadRemoteTrackingState() {
        let projectURL = projectURL
        Task.detached(priority: .userInitiated) {
            do {
                let state = try RemoteRepositoryBackgroundRunner.loadRemoteState(projectURL: projectURL)
                await MainActor.run {
                    aheadBehind = state.aheadBehind
                    currentUpstreamRemoteName = state.currentUpstreamRemoteName
                }
            } catch {
                await MainActor.run {
                    aheadBehind = .noUpstream
                    currentUpstreamRemoteName = nil
                }
            }
        }
    }

}
