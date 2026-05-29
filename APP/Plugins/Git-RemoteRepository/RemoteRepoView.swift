import MagicKit
import LibGit2Swift
import GitCoreKit
import MagicAlert
import SwiftUI
import OSLog

/// 远程仓库管理视图
/// 用于展示、添加、编辑和删除Git远程仓库
struct RemoteRepositoryView: View, SuperLog {
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM
    @Environment(\.dismiss) private var dismiss
    
    @State private var remotes: [GitRemote] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddRemoteSheet = false
    @State private var selectedRemote: GitRemote?
    @State private var showEditRemoteSheet = false
    @State private var editingRemote: GitRemote?
    @State private var aheadBehind: GitCoreKit.GitAheadBehind = .noUpstream
    @State private var currentUpstreamRemoteName: String?
    @State private var postRemoteActionMessage: String?
    @State private var isPublishingCurrentBranch = false
    
    private let verbose = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "Remote Repository Management"))
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(String(localized: "Close"))
                }
                
                Text(String(localized: "Manage Git remote repository configuration for the current project"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Main content
            VStack(spacing: 20) {
                // Remote List
                Group {
                    if isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(String(localized: "Loading..."))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                    } else if remotes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "externaldrive.badge.wifi")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text(String(localized: "No Remote Repositories"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(String(localized: "Click the button below to add your first remote repository"))
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
                                        onSelect: { selectedRemote in
                                            self.selectedRemote = selectedRemote
                                        },
                                        onEdit: { remote in
                                            editRemote(remote)
                                        },
                                        onDelete: { remote in
                                            deleteRemote(remote)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Error Message
                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Button(String(localized: "Clear")) {
                            self.errorMessage = nil
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                if let postRemoteActionMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.up.circle")
                                .foregroundColor(.blue)
                            Text(postRemoteActionMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                            Spacer()
                            Button(String(localized: "Clear")) {
                                self.postRemoteActionMessage = nil
                            }
                            .font(.caption)
                        }

                        if canPublishCurrentBranch {
                            Button {
                                publishCurrentBranch()
                            } label: {
                                if isPublishingCurrentBranch {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Text(String(localized: "Publish Current Branch"))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(isPublishingCurrentBranch)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            Divider()
            
            // Bottom toolbar
            HStack {
                Button(String(localized: "Add Remote Repository")) {
                    showAddRemoteSheet = true
                }
                .buttonStyle(.borderedProminent)

                if canPublishCurrentBranch {
                    Button {
                        publishCurrentBranch()
                    } label: {
                        if isPublishingCurrentBranch {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text(String(localized: "Publish Current Branch"))
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isPublishingCurrentBranch)
                }
                
                Spacer()
                
                Button(String(localized: "Close")) {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
        }
        .frame(width: 700, height: 500)
        .sheet(isPresented: $showAddRemoteSheet) {
            AddRemoteSheet(onAdd: { name, url in
                addRemote(name: name, url: url)
            })
        }
        .sheet(isPresented: $showEditRemoteSheet) {
            if let editingRemote = editingRemote {
                EditRemoteSheet(
                    remote: editingRemote,
                    onSave: { name, url in
                        updateRemote(originalName: editingRemote.name, newName: name, newURL: url)
                    }
                )
            }
        }
        .onAppear(perform: loadRemotes)
        .onProjectGitRefsDidChange { eventInfo in
            guard eventInfo.project.path == vm.project?.path else { return }
            loadRemotes()
        }
        .onProjectDidFetch { eventInfo in
            guard eventInfo.project.path == vm.project?.path else { return }
            loadRemoteTrackingState()
        }
        .onProjectDidPush { eventInfo in
            guard eventInfo.project.path == vm.project?.path else { return }
            loadRemoteTrackingState()
        }
        .disabled(isLoading)
    }
}

// MARK: - Actions

extension RemoteRepositoryView {
    private func loadRemotes() {
        guard let project = vm.project else {
            errorMessage = String(localized: "No project selected")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            remotes = try project.remoteList()
            loadRemoteTrackingState()
            
            if verbose {
                os_log("\(self.t)✅ Loaded \(remotes.count) remotes")
            }
        } catch {
            errorMessage = String(localized: "Failed to load remote repositories: \(error.localizedDescription)")
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to load remotes: \(error)")
            }
        }
        
        isLoading = false
    }
    
    private func addRemote(name: String, url: String) {
        guard let project = vm.project else {
            errorMessage = String(localized: "No project selected")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try project.addRemote(name: name, url: url)
            loadRemotes() // Reload list
            postRemoteActionMessage = firstPushMessage(for: name)

            if verbose {
                os_log("\(self.t)✅ Added remote: \(name) -> \(url)")
            }
        } catch {
            errorMessage = String(localized: "Failed to add remote repository: \(error.localizedDescription)")
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to add remote: \(error)")
            }
        }

        isLoading = false
    }

    private var canPublishCurrentBranch: Bool {
        remotes.isEmpty == false && aheadBehind.hasUpstream == false
    }

    private var preferredPublishRemote: GitRemote? {
        selectedRemote ?? remotes.first(where: { $0.name == "origin" }) ?? remotes.first
    }

    private func publishCurrentBranch() {
        guard let project = vm.project else {
            errorMessage = String(localized: "No project selected")
            return
        }

        guard let remote = preferredPublishRemote else {
            errorMessage = String(localized: "Please add a remote repository first")
            return
        }

        isPublishingCurrentBranch = true
        errorMessage = nil

        Task.detached(priority: .userInitiated) {
            do {
                guard let branch = try project.getCurrentBranch() else {
                    throw NSError(
                        domain: "GitOK.RemoteRepository",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Current repository has no publishable branch"]
                    )
                }

                try project.publishBranch(branch, remote: remote.name)

                await MainActor.run {
                    isPublishingCurrentBranch = false
                    postRemoteActionMessage = String(localized: "Published current branch \(branch.name), and set upstream to \(remote.name)/\(branch.name).")
                    loadRemotes()
                    alert_info(String(localized: "Published branch: \(branch.name)"))
                }
            } catch {
                await MainActor.run {
                    isPublishingCurrentBranch = false
                    errorMessage = String(localized: "Failed to publish current branch: \(error.localizedDescription)")
                    os_log(.error, "\(self.t)❌ Failed to publish current branch: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func editRemote(_ remote: GitRemote) {
        editingRemote = remote
        showEditRemoteSheet = true
        
        if verbose {
            os_log("\(self.t)📝 Edit remote: \(remote.name)")
        }
    }
    
    private func updateRemote(originalName: String, newName: String, newURL: String) {
        guard let project = vm.project else {
            errorMessage = String(localized: "No project selected")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try project.updateRemote(originalName: originalName, newName: newName, newURL: newURL)

            loadRemotes() // Reload list
            postRemoteActionMessage = String(localized: "Updated remote repository \(newName). After the remote URL changes, GitOK refreshes the current branch ahead/behind state; if the branch has no upstream yet, please publish the branch or do the first push.")

            if verbose {
                os_log("\(self.t)✅ Updated remote: \(originalName) -> \(newName): \(newURL)")
            }
        } catch {
            errorMessage = String(localized: "Failed to update remote repository: \(error.localizedDescription)")
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to update remote: \(error)")
            }
        }

        isLoading = false
    }
    
    private func deleteRemote(_ remote: GitRemote) {
        guard let project = vm.project else {
            errorMessage = String(localized: "No project selected")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let wasUpstreamRemote = remote.name == currentUpstreamRemoteName
            try project.removeRemote(name: remote.name)
            loadRemotes() // Reload list
            postRemoteActionMessage = wasUpstreamRemote
                ? String(localized: "Deleted the current upstream remote \(remote.name). The current branch will show as having no upstream; you need to re-set upstream before push/pull.")
                : String(localized: "Deleted remote repository \(remote.name). Fetch/Pull/Push operations that depend on this remote will no longer be available.")

            if selectedRemote?.id == remote.id {
                selectedRemote = nil
            }

            if verbose {
                os_log("\(self.t)✅ Removed remote: \(remote.name)")
            }
        } catch {
            errorMessage = String(localized: "Failed to delete remote repository: \(error.localizedDescription)")
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to remove remote: \(error)")
            }
        }

        isLoading = false
    }

    private func loadRemoteTrackingState() {
        guard let project = vm.project else {
            aheadBehind = .noUpstream
            currentUpstreamRemoteName = nil
            return
        }

        do {
            let state = try project.aheadBehind()
            aheadBehind = state
            currentUpstreamRemoteName = try currentUpstreamRemoteName(for: project)
        } catch {
            aheadBehind = .noUpstream
            currentUpstreamRemoteName = nil
        }
    }

    private func currentUpstreamRemoteName(for project: Project) throws -> String? {
        guard let branch = try project.getCurrentBranch()?.name else { return nil }
        let upstream = try LibGit2.getConfig(key: "branch.\(branch).remote", at: project.path, verbose: false)
        return upstream.isEmpty ? nil : upstream
    }

    private func firstPushMessage(for remoteName: String) -> String {
        if aheadBehind.hasUpstream {
            return String(localized: "Added remote repository \(remoteName). The current branch already has an upstream; GitOK has refreshed the remote tracking state.")
        }

        return String(localized: "Added remote repository \(remoteName). The current branch has no upstream yet. For the first push, please publish the branch or run `git push -u \(remoteName) <branch>`.")
    }
}

// MARK: - Preview

#Preview("Remote Repository View") {
    RemoteRepositoryView()
        .inRootView()
        .inMagicContainer()
}
