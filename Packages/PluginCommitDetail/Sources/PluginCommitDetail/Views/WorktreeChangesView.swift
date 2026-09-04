import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

private func loc(_ key: String) -> String {
    CommitDetailLocalization.string(key, bundle: .module)
}

/// 工作区变动文件列表视图。
///
/// 当 `CommitDetailViewModel.selectedCommit` 为 nil（用户点击了工作区状态条）
/// 且当前项目有未提交变更时展示。加载 `git status --porcelain` 文件列表，
/// 选中文件时通过 `projects.selectFile` 写入 Provider，右侧 git diff 插件据此展示 diff。
///
/// 外部仓库数据变化（提交 / 推送 / 分支切换）由 `CommitDetailObserver` 翻译成
/// ViewModel 的 `worktreeRevision`，这里只订阅 ViewModel，不直接监听通知。
struct WorktreeChangesView: View {
    let projects: any ProjectProviding
    @ObservedObject var viewModel: CommitDetailViewModel
    @LumiTheme private var theme

    @State private var entries: [GitStatusEntry] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var loadedProjectURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            theme.surface
        }
        .onAppear { reloadIfNeeded() }
        .onReceive(viewModel.$worktreeRevision) { _ in
            reloadIfNeeded(force: true)
        }
    }

    // MARK: - Header

    private var header: some View {
        AppToolbarContainer(
            height: 32,
            backgroundStyle: .panel,
            padding: EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
        ) {
            HStack(spacing: 6) {
                Image(systemName: "doc.on.doc")
                    .font(.appCaptionEmphasized)
                Text(loc("Changes"))
                    .font(.appCaptionEmphasized)
                Spacer()
                Text("\(entries.count)")
                    .font(.appMicro)
                    .foregroundStyle(theme.textTertiary)
            }
        }
        .borderBottom()
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
                title: loc("Unable to Load Changes"),
                description: loadError
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if entries.isEmpty {
            cleanStateView
        } else {
            // 与其他列表（CommitRailView / CommitDetailLayout）一致：
            // ScrollView + LazyVStack + AppListRow（自带选中 / hover 背景与描边），
            // 行间用 AppDivider 分隔。
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(entries) { entry in
                        fileRow(entry)
                        if entry.id != entries.last?.id {
                            AppDivider()
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Clean State View

    private var cleanStateView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // 工作区干净提示
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text(loc("Working Tree Clean"))
                        .font(.title3)
                        .fontWeight(.medium)

                    Text(loc("No uncommitted changes."))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)

                // 仓库信息
                if let project = projects.currentProject {
                    CleanStateInfoView(project: project)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private func fileRow(_ entry: GitStatusEntry) -> some View {
        let isSelected = viewModel.selectedFile == entry.path
        return AppListRow(isSelected: isSelected, action: { projects.selectFile(entry.path) }) {
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
        }
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
        if entry.isUntracked { return loc("Untracked") }
        if entry.isStaged && entry.isWorktreeModified { return loc("Staged + Modified") }
        if entry.isStaged { return loc("Staged") }
        return loc("Not Staged")
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
