import KitGit
import LumiUI
import SwiftUI

private func loc(_ key: String) -> String {
    CommitDetailLocalization.string(key, bundle: .module)
}

/// 工作区变动文件列表视图。
///
/// 当 `CommitDetailViewModel.selectedCommit` 为 nil（用户点击了工作区状态条）
/// 且当前项目有未提交变更时展示。加载 `git status --porcelain` 文件列表，
/// 选中文件时通过插件注入的 intent 写入 Provider，右侧 git diff 插件据此展示 diff。
///
/// 工作区干净（无未提交变更）时不渲染任何内容、不占布局——「干净状态视图」
/// （仓库信息 + Git 用户配置）已独立到 `PluginWorktreeClean` 插件，作为主内容区
/// 的另一块贡献展示，两个插件的内容块互斥。
///
/// 外部仓库数据变化（提交 / 推送 / 分支切换）由 `CommitDetailObserver` 翻译成
/// ViewModel 的 `worktreeRevision`，这里只订阅 ViewModel，不直接监听通知。
struct WorktreeChangesView: View {
    @ObservedObject var viewModel: CommitDetailViewModel
    let onSelectFile: (String?) -> Void
    let onDataChanged: () -> Void
    @LumiTheme private var theme

    @State private var entries: [GitStatusEntry] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var actionError: String?
    @State private var stagingPath: String?
    @State private var unstagingPath: String?
    @State private var loadedProjectURL: URL?

    var body: some View {
        Group {
            if isLoading && entries.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        theme.surface
                    }
            } else if let loadError {
                AppEmptyState(
                    icon: "exclamationmark.triangle",
                    title: loc("Unable to Load Changes"),
                    description: loadError
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    theme.surface
                }
            } else if entries.isEmpty {
                // 工作区干净（或未打开项目）：不渲染任何内容、不占布局，
                // 干净状态视图由 PluginWorktreeClean 插件独立展示。
                EmptyView()
            } else {
                VStack(spacing: 0) {
                    header
                    if let actionError {
                        Text(actionError)
                            .font(.appCaption)
                            .foregroundStyle(theme.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(theme.error.opacity(0.08))
                    }
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    theme.surface
                }
            }
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

    private func fileRow(_ entry: GitStatusEntry) -> some View {
        let isSelected = viewModel.selectedFile == entry.path
        return AppListRow(isSelected: isSelected, action: { onSelectFile(entry.path) }) {
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

                if entry.isStaged {
                    if unstagingPath == entry.path {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        AppIconButton(
                            systemImage: "minus.rectangle.on.folder",
                            label: loc("Unstage"),
                            tint: theme.primary,
                            size: .compact
                        ) {
                            unstage(entry)
                        }
                        .disabled(stagingPath != nil || unstagingPath != nil)
                    }
                } else if entry.isUntracked || entry.isWorktreeModified {
                    if stagingPath == entry.path {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        AppIconButton(
                            systemImage: "plus.rectangle.on.folder",
                            label: loc("Stage"),
                            tint: theme.primary,
                            size: .compact
                        ) {
                            stage(entry)
                        }
                        .disabled(stagingPath != nil || unstagingPath != nil)
                    }
                }
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

    // MARK: - Actions

    private func stage(_ entry: GitStatusEntry) {
        guard let projectURL = viewModel.selectedProjectURL else { return }

        stagingPath = entry.path
        actionError = nil
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try GitCommitOperation.stageFiles([entry.path], in: projectURL)
            }
            await MainActor.run {
                stagingPath = nil
                switch result {
                case .success:
                    onDataChanged()
                case .failure(let error):
                    actionError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    private func unstage(_ entry: GitStatusEntry) {
        guard let projectURL = viewModel.selectedProjectURL else { return }

        unstagingPath = entry.path
        actionError = nil
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try GitCommitOperation.unstageFiles([entry.path], in: projectURL)
            }
            await MainActor.run {
                unstagingPath = nil
                switch result {
                case .success:
                    onDataChanged()
                case .failure(let error):
                    actionError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    // MARK: - Loading

    private func reloadIfNeeded(force: Bool = false) {
        guard let projectURL = viewModel.selectedProjectURL else {
            loadedProjectURL = nil
            entries = []
            isLoading = false
            actionError = nil
            stagingPath = nil
            unstagingPath = nil
            return
        }
        if loadedProjectURL == projectURL && !force { return }

        loadedProjectURL = projectURL
        isLoading = true
        entries = []
        loadError = nil

        let url = projectURL
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
