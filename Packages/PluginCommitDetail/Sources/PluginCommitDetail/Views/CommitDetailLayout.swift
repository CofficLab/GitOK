import KitGit
import LumiUI
import SwiftUI

/// Commit 详情的整体布局（对齐旧版 GitDetailContentLayout）。
///
/// 顶部为 commit 信息头，下方为文件列表。文件列表由内部状态机异步加载
/// （git diff-tree），选中文件时通过 `onSelectFile` 写入 Provider 的
/// `selectedFile`——diff 渲染由右侧的 git diff 插件（rootview trailing pane）
/// 订阅 Provider 后独立展示。
struct CommitDetailLayout: View {
    let commit: GitCommit
    let projectURL: URL
    /// 当前选中的文件（Provider 的单一权威来源）。
    let selectedFile: String?
    /// 用户点击文件行时回调（由宿主写入 Provider）。
    let onSelectFile: (String?) -> Void
    @LumiTheme private var theme

    @State private var changes: [GitFileChange] = []
    @State private var isLoadingChanges = false
    @State private var loadError: String?
    @State private var loadedHash: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CommitInfoHeaderView(commit: commit)
            AppDivider()
            fileListPane
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { loadIfNeeded() }
        .onChange(of: commit.hash) { _, _ in loadIfNeeded() }
    }

    // MARK: - Data

    private func loadIfNeeded() {
        guard loadedHash != commit.hash else { return }
        loadedHash = commit.hash
        // 新 commit 时由 Provider 清空选中文件；这里无需自行重置。
        isLoadingChanges = true
        changes = []
        loadError = nil

        let url = projectURL
        let hash = commit.hash
        Task.detached(priority: .userInitiated) {
            let result = Result { try GitDiffLoader.loadChanges(commit: hash, in: url) }
            await MainActor.run {
                isLoadingChanges = false
                switch result {
                case .success(let loaded):
                    changes = loaded
                case .failure(let error):
                    loadError = (error as? LocalizedError)?.errorDescription
                        ?? error.localizedDescription
                }
            }
        }
    }

    // MARK: - File List Pane

    @ViewBuilder
    private var fileListPane: some View {
        VStack(spacing: 0) {
            fileListHeader
            AppDivider()
            fileListContent
        }
        .background {
            Color(nsColor: .controlBackgroundColor)
        }
    }

    private var fileListHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.on.doc")
                .font(.appCaptionEmphasized)
            Text("Files")
                .font(.appCaptionEmphasized)
            Spacer()
            Text("\(changes.count)")
                .font(.appMicro)
                .foregroundStyle(theme.textTertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var fileListContent: some View {
        if isLoadingChanges && changes.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let loadError {
            AppEmptyState(
                icon: "exclamationmark.triangle",
                title: "Unable to Load Changes",
                description: loadError
            )
        } else if changes.isEmpty {
            AppEmptyState(icon: "doc", title: "No Changes", description: "This commit has no file changes.")
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(changes) { change in
                        FileChangeRow(
                            change: change,
                            isSelected: selectedFile == change.path
                        ) {
                            onSelectFile(change.path)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Commit Info Header

/// commit 信息头：作者 + 时间 + 消息 + 短哈希。
struct CommitInfoHeaderView: View {
    @LumiTheme private var theme
    let commit: GitCommit

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(commit.message)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(spacing: 6) {
                    Text(commit.author)
                        .font(.appMicro)
                        .foregroundStyle(theme.textSecondary)
                    Text(Self.relativeTime(commit.date))
                        .font(.appMicro)
                        .foregroundStyle(theme.textTertiary)
                    Text(Self.fullDate(commit.date))
                        .font(.appMicro)
                        .foregroundStyle(theme.textTertiary)
                }
            }
            Spacer()
            Text(commit.shortHash)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(theme.textSecondary.opacity(0.1))
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private static func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private static func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - File Change Row

/// 文件变更列表行：状态图标 + 路径 + 增删行数。
struct FileChangeRow: View {
    @LumiTheme private var theme
    let change: GitFileChange
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        AppListRow(isSelected: isSelected, action: onSelect) {
            HStack(spacing: 8) {
                statusIcon
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(change.displayPath)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if change.addedLines > 0 || change.deletedLines > 0 {
                        HStack(spacing: 5) {
                            Text("+\(change.addedLines)")
                                .foregroundStyle(theme.success)
                            Text("−\(change.deletedLines)")
                                .foregroundStyle(theme.error)
                        }
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 3)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch change.status {
        case .added:
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(theme.success)
        case .deleted:
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(theme.error)
        case .modified:
            Image(systemName: "pencil.circle.fill")
                .foregroundStyle(theme.info)
        case .renamed, .copied:
            Image(systemName: "arrow.right.circle.fill")
                .foregroundStyle(theme.info)
        case .unmerged:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(theme.error)
        case .unknown:
            Image(systemName: "questionmark.circle")
                .foregroundStyle(theme.textTertiary)
        }
    }
}
