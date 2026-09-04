import KitGit
import LumiUI
import ProviderCommit
import ProviderProjects
import SwiftUI

/// 工作区变动文件列表视图。
///
/// 当 `CommitDetailProviding.selectedCommit` 为 nil（用户点击了工作区状态条）
/// 且当前项目有未提交变更时展示。加载 `git status --porcelain` 文件列表，
/// 选中文件时通过 `detail.selectFile` 写入 Provider，右侧 git diff 插件据此展示 diff。
struct WorktreeChangesView: View {
    let projects: any ProjectProviding
    let detail: any CommitDetailProviding
    @LumiTheme private var theme

    @State private var entries: [GitStatusEntry] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var loadedProjectURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            header
            AppDivider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            theme.surface
        }
        .onAppear { reloadIfNeeded() }
        .onReceive(NotificationCenter.default.publisher(for: .gitokWorktreeDataChanged)) { _ in
            reloadIfNeeded(force: true)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.on.doc")
                .font(.appCaptionEmphasized)
            Text("Changes")
                .font(.appCaptionEmphasized)
            Spacer()
            Text("\(entries.count)")
                .font(.appMicro)
                .foregroundStyle(theme.textTertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if isLoading && entries.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let loadError {
            AppEmptyState(
                icon: "exclamationmark.triangle",
                title: "Unable to Load Changes",
                description: loadError
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if entries.isEmpty {
            AppEmptyState(
                icon: "checkmark.circle",
                title: "Working Tree Clean",
                description: "No uncommitted changes."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(entries) { entry in
                    fileRow(entry)
                        .listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func fileRow(_ entry: GitStatusEntry) -> some View {
        let isSelected = detail.selectedFile == entry.path
        return Button(action: { detail.selectFile(entry.path) }) {
            HStack(spacing: 8) {
                Image(systemName: statusIcon(entry))
                    .font(.system(size: 11))
                    .foregroundStyle(statusColor(entry))
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.path)
                        .font(DesignTokens.Typography.caption1)
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(statusLabel(entry))
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(theme.textTertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 8)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status Helpers

    private func statusIcon(_ entry: GitStatusEntry) -> String {
        if entry.isUntracked { return "plus.circle" }
        let status = entry.isStaged ? entry.stagedStatus : entry.worktreeStatus
        switch status {
        case "M": return "pencil.circle"
        case "A": return "plus.circle"
        case "D": return "trash.circle"
        case "R": return "arrow.triangle.2.circlepath"
        case "C": return "doc.on.doc"
        default: return "circle"
        }
    }

    private func statusColor(_ entry: GitStatusEntry) -> Color {
        if entry.isUntracked { return theme.warning }
        if entry.isStaged { return theme.success }
        return theme.error
    }

    private func statusLabel(_ entry: GitStatusEntry) -> String {
        if entry.isUntracked { return "Untracked" }
        if entry.isStaged && entry.isWorktreeModified { return "Staged + Modified" }
        if entry.isStaged { return "Staged" }
        return "Not Staged"
    }

    // MARK: - Loading

    private func reloadIfNeeded(force: Bool = false) {
        guard let project = projects.currentProject else {
            loadedProjectURL = nil
            entries = []
            isLoading = false
            return
        }
        if loadedProjectURL == project.url && !force { return }

        loadedProjectURL = project.url
        isLoading = true
        entries = []
        loadError = nil

        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result { try GitStatusLoader.loadEntries(in: url) }
            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let loaded):
                    entries = loaded
                case .failure(let error):
                    loadError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }
}

extension Notification.Name {
    /// 工作区数据变化通知（提交/推送后由其他插件发送，触发文件列表刷新）。
    static let gitokWorktreeDataChanged = Notification.Name("com.coffic.gitok.worktreeDataChanged")
}
