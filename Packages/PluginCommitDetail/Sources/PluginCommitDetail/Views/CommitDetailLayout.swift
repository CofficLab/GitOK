import KitGit
import LumiUI
import ProviderContentView
import SwiftUI

private func loc(_ key: String) -> String {
    CommitDetailLocalization.string(key, bundle: .module)
}

/// Commit 详情的整体布局（对齐旧版 GitDetailContentLayout）。
///
/// 顶部为 commit 信息头，下方为文件列表。「当前 commit 下的变动的文件」由
/// `ProjectProviding` 统一加载维护，本视图只做展示；选中文件时通过
/// `onSelectFile` 写入 Provider 的 `currentFile`——diff 渲染由右侧的 git diff
/// 插件（rootview trailing pane）订阅 Provider 后独立展示。
struct CommitDetailLayout: View {
    let commit: GitCommit
    let projectURL: URL
    /// 当前选中的文件（Provider 的单一权威来源）。
    let selectedFile: String?
    /// 当前 commit 的分页文件缓存。
    @ObservedObject var filePageStore: CommitFilePageStore
    /// 本次刷新新增的文件路径（仅用于触发顶部进入动画，对齐 commitlist）。
    let animatedFilePaths: Set<String>
    /// 用户点击文件行时回调（由宿主写入 Provider）。
    let onSelectFile: (String?) -> Void
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CommitInfoHeaderView(commit: commit)
            AppDivider()
            fileListPane
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - File List Pane

    @ViewBuilder
    private var fileListPane: some View {
        VStack(spacing: 0) {
            fileListHeader
            fileListContent
        }
        .background {
            theme.surface
        }
    }

    private var fileListHeader: some View {
        AppToolbarContainer(
            height: 32,
            backgroundStyle: .panel,
            padding: EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
        ) {
            HStack(spacing: 6) {
                Image(systemName: "doc.on.doc")
                    .font(.appCaptionEmphasized)
                Text(loc("Files"))
                    .font(.appCaptionEmphasized)
                Spacer()
                Text(fileCountText)
                    .font(.appMicro)
                    .foregroundStyle(theme.textTertiary)
            }
        }
        .borderBottom()
    }

    @ViewBuilder
    private var fileListContent: some View {
        if filePageStore.totalCount == nil && filePageStore.isLoadingCount {
            // 首次加载（尚无任何历史数据）：展示明确的加载状态。
            ContentLoadingIndicator(loc("Loading changed files..."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filePageStore.totalCount == nil, let loadError = filePageStore.firstError {
            VStack(spacing: 10) {
                AppEmptyState(
                    icon: "exclamationmark.triangle",
                    title: loc("Unable to Load Changes"),
                    description: loadError
                )
                Button("Retry") {
                    filePageStore.retry(pageIndex: -1)
                }
                .buttonStyle(.borderless)
                .font(.appCaptionEmphasized)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filePageStore.totalCount == 0 {
            AppEmptyState(icon: "doc", title: loc("No Changes"), description: loc("This commit has no file changes."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                if let loadError = filePageStore.firstError {
                    // 刷新失败但保留旧列表：顶部横幅提示，不清空内容。
                    HStack(spacing: 8) {
                        Text(loadError)
                            .font(.appCaption)
                            .foregroundStyle(theme.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let failedPage = filePageStore.firstFailedPageIndex {
                            Button("Retry") {
                                filePageStore.retry(pageIndex: failedPage)
                            }
                            .buttonStyle(.borderless)
                            .font(.appCaptionEmphasized)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(theme.error.opacity(0.08))
                }
                // 每一行只是一个稳定索引；真正的 GitFileChange 按页按需取回。
                // 未加载的行保留固定高度，避免分页返回时滚动位置跳动。
                ZStack(alignment: .top) {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(0..<(filePageStore.totalCount ?? 0), id: \.self) { index in
                                Group {
                                    if let change = filePageStore.change(at: index) {
                                        FileChangeRow(
                                            change: change,
                                            isSelected: selectedFile == change.path
                                        ) {
                                            onSelectFile(change.path)
                                        }
                                        .transition(
                                            animatedFilePaths.contains(change.path)
                                                ? .asymmetric(
                                                    insertion: .move(edge: .top).combined(with: .opacity),
                                                    removal: .opacity
                                                )
                                                : .identity
                                        )
                                    } else {
                                        FileChangePlaceholderRow()
                                    }
                                }
                                .onAppear {
                                    let pageIndex = index / CommitFilePageStore.pageSize
                                    let positionInPage = index % CommitFilePageStore.pageSize
                                    filePageStore.requestPage(at: pageIndex)
                                    // 进入一页的头尾时各预取相邻页，向上和向下
                                    // 滚动都能减少占位行停留时间。
                                    if positionInPage < 10 {
                                        filePageStore.requestPage(at: pageIndex - 1)
                                    }
                                    if positionInPage >= CommitFilePageStore.pageSize - 10 {
                                        filePageStore.requestPage(at: pageIndex + 1)
                                    }
                                }
                                if index + 1 < (filePageStore.totalCount ?? 0) {
                                    AppDivider()
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    if filePageStore.isLoading {
                        VStack(spacing: 3) {
                            ProgressView()
                                .progressViewStyle(.linear)
                                .frame(height: 2)
                            Text(loc("Loading more files..."))
                                .font(.appMicro)
                                .foregroundStyle(theme.textTertiary)
                        }
                            .padding(.horizontal, 2)
                    }
                }
            }
        }
    }

    private var fileCountText: String {
        if let totalCount = filePageStore.totalCount {
            return "\(totalCount)"
        }
        return filePageStore.isLoadingCount ? "…" : "—"
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
                    .font(DesignTokens.Typography.subheadline.weight(.semibold))
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(change.displayPath)
                        .font(DesignTokens.Typography.caption1.weight(.medium))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 5) {
                        statusIcon
                            .foregroundStyle(CommitDetailChangeColors.commitStatus(change.status))
                            .frame(width: 16)

                        if change.addedLines > 0 || change.deletedLines > 0 {
                            Text("+\(change.addedLines)")
                                .foregroundStyle(theme.success)
                            Text("−\(change.deletedLines)")
                                .foregroundStyle(theme.error)
                        }
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 3)
            .frame(minHeight: 34)
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(CommitDetailChangeColors.commitStatus(change.status))
                .frame(width: 3)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch change.status {
        case .added:
            Image(systemName: "plus.circle.fill")
        case .deleted:
            Image(systemName: "minus.circle.fill")
        case .modified:
            Image(systemName: "pencil.circle.fill")
        case .renamed, .copied:
            Image(systemName: "arrow.right.circle.fill")
        case .unmerged:
            Image(systemName: "exclamationmark.triangle.fill")
        case .unknown:
            Image(systemName: "questionmark.circle")
        }
    }
}

private struct FileChangePlaceholderRow: View {
    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(.secondary.opacity(0.12))
                .frame(width: 16, height: 16)
            RoundedRectangle(cornerRadius: 3)
                .fill(.secondary.opacity(0.12))
                .frame(maxWidth: .infinity)
                .frame(height: 12)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
    }
}
