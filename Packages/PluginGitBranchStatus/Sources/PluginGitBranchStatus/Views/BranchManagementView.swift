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

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                newBranchSection
                Divider()
                AppSearchBar(text: $searchText, placeholder: "Search branches")
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
            Text("New Branch")
                .font(.headline)
            HStack(spacing: 8) {
                AppInputField("Branch name", text: $newBranchName)
                AppIconButton(
                    systemImage: "plus",
                    label: "New Branch",
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
            Text("Switch Branch")
                .font(.headline)
            if isLoading {
                ProgressView("Loading branches...")
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if filteredBranches.isEmpty {
                ContentUnavailableView(
                    "No branches yet",
                    systemImage: "arrow.triangle.branch"
                )
                .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(filteredBranches) { branch in
                        BranchRowView(
                            branch: branch,
                            onSwitch: { switchBranch(branch) },
                            onDelete: { deleteBranch(branch) }
                        )
                    }
                }
            }
        }
    }

    private var remoteBranchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Remote Branches")
                .font(.headline)
            ForEach(filteredRemoteBranches) { branch in
                HStack(spacing: 8) {
                    Image(systemName: "network")
                        .foregroundStyle(theme.textSecondary)
                    Text(branch.name)
                        .font(.system(size: 13))
                        .foregroundStyle(theme.textSecondary)
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
}

/// 分支行：切换 / 删除。
public struct BranchRowView: View {
    let branch: GitBranchSummary
    let onSwitch: () -> Void
    let onDelete: () -> Void
    @LumiTheme private var theme

    public init(branch: GitBranchSummary, onSwitch: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.branch = branch
        self.onSwitch = onSwitch
        self.onDelete = onDelete
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
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(branch.isCurrent ? theme.surface : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
