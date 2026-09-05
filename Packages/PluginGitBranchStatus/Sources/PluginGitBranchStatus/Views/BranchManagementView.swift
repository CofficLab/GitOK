import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 分支管理面板：新建、搜索、切换/删除本地分支、列出远程分支
/// （对齐旧版 BranchManagementView 的核心能力）。
public struct BranchManagementView: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @LumiTheme private var theme

    @State private var branches: [GitBranchSummary] = []
    @State private var remoteBranches: [GitBranchSummary] = []
    @State private var newBranchName = ""
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var branchToRename: GitBranchSummary?
    @State private var renameBranchName = ""
    @State private var branchToSetUpstream: GitBranchSummary?
    @State private var selectedUpstreamBranch = ""
    @State private var pendingRemoteBranchDeletion: String?

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                newBranchSection
                Divider()
                AppSearchBar(text: $searchText, placeholder: LocalizedStringKey(LumiPluginLocalization.string("Search branches", bundle: .module)))
                branchListSection
                if !remoteBranches.isEmpty {
                    Divider()
                    remoteBranchesSection
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(theme.warning)
                }
            }
            .padding(20)
        }
        .onAppear(perform: loadBranches)
        .onReceive(observation.$lastEvent) { event in
            if case .dataChanged = event {
                loadBranches()
            }
        }
        .sheet(item: $branchToRename) { branch in
            renameSheet(branch)
        }
        .sheet(item: $branchToSetUpstream) { branch in
            upstreamSheet(branch)
        }
        .alert(
            LumiPluginLocalization.string("Confirm Delete Remote Branch?", bundle: .module),
            isPresented: Binding(
                get: { pendingRemoteBranchDeletion != nil },
                set: { isPresented in
                    if !isPresented { pendingRemoteBranchDeletion = nil }
                }
            )
        ) {
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {
                pendingRemoteBranchDeletion = nil
            }
            Button(LumiPluginLocalization.string("Delete Remote Branch", bundle: .module), role: .destructive) {
                guard let branch = pendingRemoteBranchDeletion else { return }
                pendingRemoteBranchDeletion = nil
                deleteRemoteBranch(branch)
            }
        } message: {
            if let branch = pendingRemoteBranchDeletion {
                Text(String(format: LumiPluginLocalization.string(
                    "Delete remote branch \"%@\"?",
                    bundle: .module
                ), branch))
            }
        }
    }

    private var projectURL: URL? {
        projects.currentProject?.url
    }

    private var filteredBranches: [GitBranchSummary] {
        BranchLogic.filter(branches: branches, query: searchText)
    }

    private var filteredRemoteBranches: [GitBranchSummary] {
        BranchLogic.filter(branches: remoteBranches, query: searchText)
    }

    private var newBranchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LumiPluginLocalization.string("New Branch", bundle: .module))
                .font(.headline)
            HStack(spacing: 8) {
                AppInputField(LocalizedStringKey(LumiPluginLocalization.string("Branch name", bundle: .module)), text: $newBranchName)
                AppIconButton(
                    systemImage: "plus",
                    label: LumiPluginLocalization.string("New Branch", bundle: .module),
                    tint: theme.primary
                ) {
                    createBranch()
                }
                .disabled(newBranchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
    }

    private var branchListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LumiPluginLocalization.string("Switch Branch", bundle: .module))
                .font(.headline)
            if isLoading {
                ProgressView(LumiPluginLocalization.string("Loading branches...", bundle: .module))
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if filteredBranches.isEmpty {
                ContentUnavailableView(
                    LumiPluginLocalization.string("No branches yet", bundle: .module),
                    systemImage: "arrow.triangle.branch"
                )
                .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(filteredBranches) { branch in
                        BranchRowView(
                            branch: branch,
                            onSwitch: { switchBranch(branch) },
                            onDelete: { deleteBranch(branch) },
                            onRename: { beginRename(branch) },
                            onPublish: { publishBranch(branch) },
                            onSetUpstream: { beginSetUpstream(branch) },
                            onUnsetUpstream: { unsetUpstream(branch) }
                        )
                    }
                }
            }
        }
    }

    private var remoteBranchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LumiPluginLocalization.string("Remote Branches", bundle: .module))
                .font(.headline)
            ForEach(filteredRemoteBranches) { branch in
                HStack(spacing: 8) {
                    Image(systemName: "network")
                        .foregroundStyle(theme.textSecondary)
                    Text(branch.name)
                        .font(.system(size: 13))
                        .foregroundStyle(theme.textSecondary)
                    Spacer()
                    AppIconButton(
                        systemImage: "trash",
                        label: LumiPluginLocalization.string("Delete Remote Branch", bundle: .module),
                        tint: theme.warning
                    ) {
                        pendingRemoteBranchDeletion = branch.name
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func loadBranches() {
        guard let url = projectURL else {
            branches = []
            remoteBranches = []
            return
        }
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                let all = try GitBranchOperation.listBranches(in: url)
                let local = all.filter { !$0.isRemote }
                let remote = all.filter { $0.isRemote }
                await MainActor.run {
                    branches = local
                    remoteBranches = remote
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    @MainActor
    private func createBranch() {
        guard let url = projectURL else { return }
        let name = newBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        isLoading = true
        Task.detached(priority: .userInitiated) {
            do {
                try GitBranchOperation.createBranch(named: name, in: url)
                try GitBranchOperation.checkoutBranch(named: name, in: url)
                await MainActor.run {
                    newBranchName = ""
                    isLoading = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    @MainActor
    private func switchBranch(_ branch: GitBranchSummary) {
        guard let url = projectURL else { return }
        isLoading = true
        Task.detached(priority: .userInitiated) {
            do {
                try GitBranchOperation.checkoutBranch(named: branch.name, in: url)
                await MainActor.run {
                    isLoading = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    @MainActor
    private func deleteBranch(_ branch: GitBranchSummary) {
        guard let url = projectURL else { return }
        isLoading = true
        Task.detached(priority: .userInitiated) {
            do {
                try GitBranchOperation.deleteBranch(named: branch.name, in: url)
                await MainActor.run {
                    isLoading = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func beginRename(_ branch: GitBranchSummary) {
        renameBranchName = branch.name
        branchToRename = branch
    }

    private func renameBranch(_ branch: GitBranchSummary) {
        guard let url = projectURL else { return }
        let newName = renameBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else { return }
        let oldName = branch.name
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                try GitBranchOperation.renameBranch(from: oldName, to: newName, in: url)
                await MainActor.run {
                    branchToRename = nil
                    isLoading = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func beginSetUpstream(_ branch: GitBranchSummary) {
        selectedUpstreamBranch = remoteBranches.first?.name ?? ""
        branchToSetUpstream = branch
    }

    private func setUpstream(_ branch: GitBranchSummary) {
        guard let url = projectURL else { return }
        let upstream = selectedUpstreamBranch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !upstream.isEmpty else { return }
        let local = branch.name
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                try GitBranchOperation.setUpstream(
                    localBranch: local,
                    upstreamBranch: upstream,
                    in: url
                )
                await MainActor.run {
                    branchToSetUpstream = nil
                    isLoading = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func unsetUpstream(_ branch: GitBranchSummary) {
        guard let url = projectURL else { return }
        let local = branch.name
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                try GitBranchOperation.unsetUpstream(localBranch: local, in: url)
                await MainActor.run {
                    isLoading = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func publishBranch(_ branch: GitBranchSummary) {
        guard let url = projectURL else { return }
        let local = branch.name
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                try GitBranchOperation.publishBranch(localBranch: local, in: url)
                await MainActor.run {
                    isLoading = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func deleteRemoteBranch(_ branchName: String) {
        guard let url = projectURL else { return }
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                try GitBranchOperation.deleteRemoteBranch(named: branchName, in: url)
                await MainActor.run {
                    isLoading = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func renameSheet(_ branch: GitBranchSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LumiPluginLocalization.string("Rename Branch", bundle: .module))
                .font(.headline)
            TextField(
                LumiPluginLocalization.string("New branch name", bundle: .module),
                text: $renameBranchName
            )
            .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button(LumiPluginLocalization.string("Cancel", bundle: .module)) {
                    branchToRename = nil
                }
                Button(LumiPluginLocalization.string("Rename", bundle: .module)) {
                    renameBranch(branch)
                }
                .buttonStyle(.borderedProminent)
                .disabled(renameBranchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
        .padding(20)
        .frame(width: 340)
    }

    private func upstreamSheet(_ branch: GitBranchSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LumiPluginLocalization.string("Set Upstream", bundle: .module))
                .font(.headline)
            if remoteBranches.isEmpty {
                Text(LumiPluginLocalization.string("No remote branches available.", bundle: .module))
                    .foregroundStyle(theme.textSecondary)
            } else {
                Picker(
                    LumiPluginLocalization.string("Upstream branch", bundle: .module),
                    selection: $selectedUpstreamBranch
                ) {
                    ForEach(remoteBranches) { remote in
                        Text(remote.name).tag(remote.name)
                    }
                }
            }
            HStack {
                Spacer()
                Button(LumiPluginLocalization.string("Cancel", bundle: .module)) {
                    branchToSetUpstream = nil
                }
                Button(LumiPluginLocalization.string("Set Upstream", bundle: .module)) {
                    setUpstream(branch)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedUpstreamBranch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}

/// 分支行：切换 / 删除。
public struct BranchRowView: View {
    let branch: GitBranchSummary
    let onSwitch: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    let onPublish: () -> Void
    let onSetUpstream: () -> Void
    let onUnsetUpstream: () -> Void
    @LumiTheme private var theme
    @State private var showDeleteAlert = false

    public init(
        branch: GitBranchSummary,
        onSwitch: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onRename: @escaping () -> Void,
        onPublish: @escaping () -> Void,
        onSetUpstream: @escaping () -> Void,
        onUnsetUpstream: @escaping () -> Void
    ) {
        self.branch = branch
        self.onSwitch = onSwitch
        self.onDelete = onDelete
        self.onRename = onRename
        self.onPublish = onPublish
        self.onSetUpstream = onSetUpstream
        self.onUnsetUpstream = onUnsetUpstream
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: branch.isCurrent ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(branch.isCurrent ? theme.primary : theme.textTertiary)
            Text(branch.name)
                .font(.system(size: 13))
                .foregroundStyle(branch.isCurrent ? theme.textPrimary : theme.textSecondary)
            Spacer()
            if branch.isCurrent {
                Text("current")
                    .font(.appCaption)
                    .foregroundStyle(theme.textTertiary)
            } else {
                AppIconButton(
                    systemImage: "arrow.triangle.branch",
                    label: "Switch",
                    tint: theme.textSecondary
                ) {
                    onSwitch()
                }
            }
            if !branch.isCurrent {
                AppIconButton(
                    systemImage: "trash",
                    label: "Delete",
                    tint: theme.warning
                ) {
                    onDelete()
                }
            }
            Menu {
                Button(LumiPluginLocalization.string("Rename Branch", bundle: .module), systemImage: "pencil", action: onRename)
                Button(LumiPluginLocalization.string("Set Upstream", bundle: .module), systemImage: "link", action: onSetUpstream)
                Button(LumiPluginLocalization.string("Publish Branch", bundle: .module), systemImage: "icloud.and.arrow.up", action: onPublish)
                Button(LumiPluginLocalization.string("Unset Upstream", bundle: .module), systemImage: "link.badge.minus", action: onUnsetUpstream)
                if !branch.isCurrent {
                    Divider()
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label(LumiPluginLocalization.string("Delete Local Branch", bundle: .module), systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(branch.isCurrent ? theme.surface : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .alert(
            LumiPluginLocalization.string("Confirm Delete Branch", bundle: .module),
            isPresented: $showDeleteAlert
        ) {
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {}
            Button(LumiPluginLocalization.string("Delete", bundle: .module), role: .destructive, action: onDelete)
        } message: {
            Text(String(format: LumiPluginLocalization.string(
                "Delete local branch \"%@\"? Git will prevent deleting unmerged branches.",
                bundle: .module
            ), branch.name))
        }
    }
}

/// 分支过滤逻辑。
public enum BranchLogic {
    public static func filter(branches: [GitBranchSummary], query: String) -> [GitBranchSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return branches }
        return branches.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }
}
