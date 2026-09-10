import KitGit
import LumiUI
import ProviderGitRepositoryWatch
import ProviderGit
import ProviderProjects
import AppKit
import SwiftUI

private let commitPageSize = 50
private let jumpToOldestTriggerDistance: CGFloat = 220

/// Commit 列表 Rail 视图：显示当前打开项目的提交历史。
///
/// 作为 Rail 注入根布局（位于侧边栏右侧、内容区左侧）。订阅
/// `ProjectProviding` 的观察者事件；`currentProject` 变化时异步读取
/// 该仓库的 commit 列表（后台线程执行 git CLI，主线程更新）。
///
/// 同时订阅 `GitRepositoryWatching` 事件（FSEventStream 监听 `.git` 目录），
/// 感知外部修改（终端 `git commit` / `git checkout` / 其他工具改仓库）后自动刷新。
///
/// 选中 commit 的状态由 `ProjectProviding` 统一维护（Lumi 式"单 Provider
/// 多处消费"）：
/// - 行点击把选中的 commit 写入 Provider，主内容区（PluginCommitDetail）
///   与 diff 视图（PluginGitDiff）据此展示；
/// - 本视图据 Provider 的选中状态高亮当前行；
/// - 切换项目时 Provider 内部联动清空选择，避免旧项目的选中残留。
///
/// 视觉对齐旧版 GitOK 的 commit 行布局（message / 作者 +
/// 相对时间 / 完整日期 / tag），并使用 LumiUI 组件（AppToolbarContainer /
/// AppListRow / AppAvatar / AppTag / AppEmptyState / AppDivider）保证与整体
/// 设计语言一致。
struct CommitRailView: View {
    private enum CommitScrollAnchor: Hashable {
        case latest
        case oldest
    }

    let projects: any ProjectProviding
    let git: any GitProviding
    let gitWatch: (any GitRepositoryWatching)?
    @LumiTheme private var theme
    @StateObject private var projectObservation: ProjectObservationModel
    @StateObject private var gitWatchObservation: GitRepositoryWatchObservationModel

    @State private var commits: [GitCommit] = []
    /// 回到最近提交时恢复的首屏快照，始终限制为一页，避免额外保留完整历史。
    @State private var latestCommitSnapshot: [GitCommit] = []
    /// 是否正在展示历史末端的一页，而不是完整的连续分页列表。
    @State private var isShowingOldestPage = false
    /// 当前最早页在完整 Git 日志中的 offset；向上滚动时从这里向前分页。
    @State private var oldestLoadedOffset: Int?
    @State private var unpushedHashes: Set<String> = []
    @State private var isLoading = false
    @State private var loadedProjectURL: URL?
    @State private var loadError: String?
    @State private var hasMoreCommits = true
    /// 下一页相对于 Git 日志的稳定偏移量，不直接依赖去重后的 UI 数量。
    @State private var nextCommitOffset = 0
    /// 加载序号：只接受最后一次刷新结果，避免旧任务覆盖新项目或新快照。
    @State private var loadToken = 0
    /// 本次刷新新增的 commit，只用于触发顶部进入动画。
    @State private var animatedCommitHashes: Set<String> = []
    /// 首尾锚点是否处于可见区域，用于控制快速滚动按钮。
    @State private var isLatestCommitVisible = true
    @State private var isOldestCommitVisible = false
    @State private var hasScrolledDownEnough = false
    /// 点击“跳到第一个提交”后，定位并加载历史末端一页的状态。
    @State private var isJumpingToOldest = false

    // Push 状态
    @State private var pushPopoverCommitHash: String?
    @State private var isPushing = false
    @State private var pushError: String?

    // 历史操作状态
    @State private var pendingUndo: GitCommit?
    @State private var pendingRevert: GitCommit?
    @State private var pendingSoftReset: GitCommit?
    @State private var pendingMixedReset: GitCommit?
    @State private var pendingHardReset: GitCommit?
    @State private var pendingSquash: GitCommit?
    @State private var squashMessage = ""
    @State private var undoingHash: String?
    @State private var revertingHash: String?
    @State private var softResettingHash: String?
    @State private var mixedResettingHash: String?
    @State private var hardResettingHash: String?
    @State private var squashingHash: String?
    @State private var historyError: String?

    // Tag 操作状态
    @State private var pendingCreateTag: GitCommit?
    @State private var pendingCreateAnnotatedTag: GitCommit?
    @State private var tagName = ""
    @State private var annotatedTagName = ""
    @State private var annotatedTagMessage = ""
    @State private var pendingDeleteTag: String?
    @State private var pendingDeleteRemoteTag: String?
    @State private var creatingTagHash: String?
    @State private var creatingAnnotatedTagHash: String?
    @State private var deletingTagName: String?
    @State private var pushingTagName: String?
    @State private var deletingRemoteTagName: String?
    @State private var tagError: String?

    init(
        projects: any ProjectProviding,
        git: any GitProviding,
        gitWatch: (any GitRepositoryWatching)? = nil
    ) {
        self.projects = projects
        self.git = git
        self.gitWatch = gitWatch
        _projectObservation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
        _gitWatchObservation = StateObject(wrappedValue: GitRepositoryWatchObservationModel(gitWatch: gitWatch))
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            theme.surface
        }
        .alert(
            LumiPluginLocalization.string("Confirm Revert", bundle: .module),
            isPresented: Binding(
                get: { pendingRevert != nil },
                set: { isPresented in
                    if !isPresented { pendingRevert = nil }
                }
            )
        ) {
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {
                pendingRevert = nil
            }
            Button(LumiPluginLocalization.string("Revert", bundle: .module), role: .destructive) {
                guard let commit = pendingRevert else { return }
                pendingRevert = nil
                performRevert(commit)
            }
        } message: {
            if let commit = pendingRevert {
                Text(String(
                    format: LumiPluginLocalization.string("Revert commit \"%@\"? This creates a new commit.", bundle: .module),
                    commit.message
                ))
            }
        }
        .alert(
            LumiPluginLocalization.string("Confirm Undo Commit?", bundle: .module),
            isPresented: Binding(
                get: { pendingUndo != nil },
                set: { isPresented in
                    if !isPresented { pendingUndo = nil }
                }
            )
        ) {
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {
                pendingUndo = nil
            }
            Button(LumiPluginLocalization.string("Undo", bundle: .module), role: .destructive) {
                guard let commit = pendingUndo else { return }
                pendingUndo = nil
                performUndo(commit)
            }
        } message: {
            Text(LumiPluginLocalization.string(
                "After undoing, this commit's changes will remain in the working tree.",
                bundle: .module
            ))
        }
        .alert(
            LumiPluginLocalization.string("Confirm Soft Reset?", bundle: .module),
            isPresented: Binding(
                get: { pendingSoftReset != nil },
                set: { isPresented in
                    if !isPresented { pendingSoftReset = nil }
                }
            )
        ) {
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {
                pendingSoftReset = nil
            }
            Button(LumiPluginLocalization.string("Soft Reset", bundle: .module)) {
                guard let commit = pendingSoftReset else { return }
                pendingSoftReset = nil
                performSoftReset(to: commit)
            }
        } message: {
            Text(LumiPluginLocalization.string(
                "HEAD will move to this commit. Changes from subsequent commits will be preserved in the staging area.",
                bundle: .module
            ))
        }
        .alert(
            LumiPluginLocalization.string("Confirm Mixed Reset?", bundle: .module),
            isPresented: Binding(
                get: { pendingMixedReset != nil },
                set: { isPresented in
                    if !isPresented { pendingMixedReset = nil }
                }
            )
        ) {
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {
                pendingMixedReset = nil
            }
            Button(LumiPluginLocalization.string("Mixed Reset", bundle: .module)) {
                guard let commit = pendingMixedReset else { return }
                pendingMixedReset = nil
                performMixedReset(to: commit)
            }
        } message: {
            Text(LumiPluginLocalization.string(
                "HEAD will move to this commit. Changes from subsequent commits will be preserved in the working directory but unstaged.",
                bundle: .module
            ))
        }
        .alert(
            LumiPluginLocalization.string("Confirm Hard Reset?", bundle: .module),
            isPresented: Binding(
                get: { pendingHardReset != nil },
                set: { isPresented in
                    if !isPresented { pendingHardReset = nil }
                }
            )
        ) {
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {
                pendingHardReset = nil
            }
            Button(LumiPluginLocalization.string("Hard Reset", bundle: .module), role: .destructive) {
                guard let commit = pendingHardReset else { return }
                pendingHardReset = nil
                performHardReset(to: commit)
            }
        } message: {
            Text(LumiPluginLocalization.string(
                "HEAD, the staging area, and tracked working files will be discarded back to this commit. This cannot be undone.",
                bundle: .module
            ))
        }
        .alert(
            LumiPluginLocalization.string("Confirm Squash Commits?", bundle: .module),
            isPresented: Binding(
                get: { pendingSquash != nil },
                set: { isPresented in
                    if !isPresented { pendingSquash = nil }
                }
            )
        ) {
            TextField(
                LumiPluginLocalization.string("Squash commit message", bundle: .module),
                text: $squashMessage
            )
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {
                pendingSquash = nil
            }
            Button(LumiPluginLocalization.string("Squash", bundle: .module)) {
                guard let commit = pendingSquash else { return }
                pendingSquash = nil
                performSquash(to: commit)
            }
            .disabled(squashMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            if let commit = pendingSquash,
               let index = commits.firstIndex(where: { $0.hash == commit.hash }) {
                Text(String(format: LumiPluginLocalization.string(
                    "This will combine %lld commits from HEAD to this commit into one.",
                    bundle: .module
                ), index + 1))
            }
        }
        .alert(
            LumiPluginLocalization.string("Create Tag", bundle: .module),
            isPresented: Binding(
                get: { pendingCreateTag != nil },
                set: { isPresented in
                    if !isPresented { pendingCreateTag = nil }
                }
            )
        ) {
            TextField(
                LumiPluginLocalization.string("Tag name", bundle: .module),
                text: $tagName
            )
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {
                pendingCreateTag = nil
            }
            Button(LumiPluginLocalization.string("Create", bundle: .module)) {
                guard let commit = pendingCreateTag else { return }
                pendingCreateTag = nil
                performCreateTag(at: commit)
            }
            .disabled(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            if let commit = pendingCreateTag {
                Text(commit.message)
            }
        }
        .alert(
            LumiPluginLocalization.string("Create Annotated Tag", bundle: .module),
            isPresented: Binding(
                get: { pendingCreateAnnotatedTag != nil },
                set: { isPresented in
                    if !isPresented { pendingCreateAnnotatedTag = nil }
                }
            )
        ) {
            TextField(
                LumiPluginLocalization.string("Tag name", bundle: .module),
                text: $annotatedTagName
            )
            TextField(
                LumiPluginLocalization.string("Tag message", bundle: .module),
                text: $annotatedTagMessage
            )
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {
                pendingCreateAnnotatedTag = nil
            }
            Button(LumiPluginLocalization.string("Create", bundle: .module)) {
                guard let commit = pendingCreateAnnotatedTag else { return }
                pendingCreateAnnotatedTag = nil
                performCreateAnnotatedTag(at: commit)
            }
            .disabled(
                annotatedTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || annotatedTagMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        } message: {
            if let commit = pendingCreateAnnotatedTag {
                Text(commit.message)
            }
        }
        .alert(
            LumiPluginLocalization.string("Confirm Delete Tag?", bundle: .module),
            isPresented: Binding(
                get: { pendingDeleteTag != nil },
                set: { isPresented in
                    if !isPresented { pendingDeleteTag = nil }
                }
            )
        ) {
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {
                pendingDeleteTag = nil
            }
            Button(LumiPluginLocalization.string("Delete Tag", bundle: .module), role: .destructive) {
                guard let tag = pendingDeleteTag else { return }
                pendingDeleteTag = nil
                performDeleteTag(named: tag)
            }
        } message: {
            if let tag = pendingDeleteTag {
                Text(String(format: LumiPluginLocalization.string(
                    "Delete tag \"%@\"? This cannot be undone.",
                    bundle: .module
                ), tag))
            }
        }
        .alert(
            LumiPluginLocalization.string("Confirm Delete Remote Tag?", bundle: .module),
            isPresented: Binding(
                get: { pendingDeleteRemoteTag != nil },
                set: { isPresented in
                    if !isPresented { pendingDeleteRemoteTag = nil }
                }
            )
        ) {
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {
                pendingDeleteRemoteTag = nil
            }
            Button(LumiPluginLocalization.string("Delete Remote Tag", bundle: .module), role: .destructive) {
                guard let tag = pendingDeleteRemoteTag else { return }
                pendingDeleteRemoteTag = nil
                performDeleteRemoteTag(named: tag)
            }
        } message: {
            if let tag = pendingDeleteRemoteTag {
                Text(String(format: LumiPluginLocalization.string(
                    "Delete remote tag \"%@\"?",
                    bundle: .module
                ), tag))
            }
        }
        // 项目 / 选中 commit / 仓库数据变化 → 刷新列表或选中态高亮。
        .onReceive(projectObservation.$revision) { _ in
            reloadIfNeeded()
            refreshSelectionState()
        }
        // dataChanged（提交/推送后）→ 即使项目未变也强制刷新列表。
        .onReceive(projectObservation.$lastEvent) { event in
            if case .dataChanged = event {
                reloadIfNeeded(force: true)
            }
        }
        // .git 目录变化（HEAD / refs 等）→ 强制刷新 commit 列表
        // 感知外部修改（终端 git commit / checkout / 其他工具改仓库）
        // 注意：不响应 workingTreeChanged，工作区文件变化不影响 commit 列表
        .onReceive(gitWatchObservation.$lastEvent) { event in
            switch event {
            case .headChanged, .refsChanged:
                reloadIfNeeded(force: true)
            default:
                break
            }
        }
        .onAppear { reloadIfNeeded() }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let project = projects.currentProject,
           FileManager.default.fileExists(atPath: project.url.path) {
            commitListContent(for: project)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func commitListContent(for project: Project) -> some View {
        if isLoading && commits.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if commits.isEmpty, let loadError {
            AppEmptyState(
                icon: "exclamationmark.triangle",
                title: LumiPluginLocalization.string("Unable to Load Commits", bundle: .module),
                description: loadError
            )
        } else if commits.isEmpty {
            AppEmptyState(
                icon: "clock",
                title: LumiPluginLocalization.string("No Commits", bundle: .module),
                description: LumiPluginLocalization.string("This repository has no commits yet.", bundle: .module)
            )
        } else {
            VStack(spacing: 0) {
                if let loadError {
                    Text(loadError)
                        .font(.appCaption)
                        .foregroundStyle(theme.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(theme.error.opacity(0.08))
                }
                if let historyError {
                    Text(historyError)
                        .font(.appCaption)
                        .foregroundStyle(theme.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(theme.error.opacity(0.08))
                }
                if let tagError {
                    Text(tagError)
                        .font(.appCaption)
                        .foregroundStyle(theme.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(theme.error.opacity(0.08))
                }

                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        if shouldShowJumpToLatest {
                            jumpToLatestButton(using: proxy)
                        }

                        ZStack(alignment: .top) {
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 0) {
                                    CommitScrollOffsetReader { offset, maximumOffset in
                                        updateCommitScrollPosition(
                                            offset: offset,
                                            maximumOffset: maximumOffset
                                        )
                                    }
                                    .frame(width: 0, height: 0)

                                    LazyVStack(spacing: 0) {
                                        Color.clear
                                            .frame(height: 1)
                                            .id(CommitScrollAnchor.latest)

                                        ForEach(commits) { commit in
                                            commitRow(commit)
                                                .onAppear {
                                                    loadMoreIfNeeded(after: commit)
                                                    loadMoreTowardsLatestIfNeeded(
                                                        when: commit,
                                                        using: proxy
                                                    )
                                                }
                                            if commit.id != commits.last?.id {
                                                AppDivider()
                                            }
                                        }

                                        Color.clear
                                            .frame(height: 1)
                                            .id(CommitScrollAnchor.oldest)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.linear)
                                    .frame(height: 2)
                                    .padding(.horizontal, 2)
                            }
                        }

                        if shouldShowJumpToOldest {
                            jumpToOldestButton(using: proxy)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    // MARK: - Commit Row

    private func commitRow(_ commit: GitCommit) -> some View {
        let isUnpushed = unpushedHashes.contains(commit.hash)
        return AppListRow(isSelected: isSelected(commit), action: { select(commit) }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(commit.message)
                        .font(DesignTokens.Typography.subheadline.weight(.medium))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 8)
                    if !commit.tags.isEmpty {
                        ForEach(commit.tags.prefix(2), id: \.self) { tag in
                            AppTag(tag, systemImage: "tag", style: .accent)
                        }
                    }
                    // 未推送 commit 显示 push 按钮
                    if isUnpushed {
                        pushButton(for: commit)
                    }
                }
                HStack(spacing: 6) {
                    CommitAuthorAvatarView(author: commit.author, email: commit.authorEmail)
                    Text(commit.author)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(Self.relativeTime(commit.date))
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(theme.textTertiary)
                }
                Text(Self.fullDate(commit.date))
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(theme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5)
        }
        .transition(
            animatedCommitHashes.contains(commit.hash)
                ? .asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                )
                : .identity
        )
        .popover(
            isPresented: Binding(
                get: { pushPopoverCommitHash == commit.hash },
                set: { if !$0 { pushPopoverCommitHash = nil; pushError = nil } }
            )
        ) {
            pushPopoverContent(for: commit)
        }
        .contextMenu {
            Button {
                tagError = nil
                tagName = ""
                pendingCreateTag = commit
            } label: {
                Label(
                    LumiPluginLocalization.string("Create Tag", bundle: .module),
                    systemImage: "tag"
                )
            }
            .disabled(isOperationRunning)

            Button {
                tagError = nil
                annotatedTagName = ""
                annotatedTagMessage = commit.message
                pendingCreateAnnotatedTag = commit
            } label: {
                Label(
                    LumiPluginLocalization.string("Create Annotated Tag", bundle: .module),
                    systemImage: "tag.fill"
                )
            }
            .disabled(isOperationRunning)

            if !commit.tags.isEmpty {
                Menu {
                    ForEach(commit.tags, id: \.self) { tag in
                        Menu {
                            Button {
                                performPushTag(named: tag)
                            } label: {
                                Label(
                                    LumiPluginLocalization.string("Push Tag", bundle: .module),
                                    systemImage: "arrow.up.circle"
                                )
                            }

                            Button {
                                pendingDeleteRemoteTag = tag
                            } label: {
                                Label(
                                    LumiPluginLocalization.string("Delete Remote Tag", bundle: .module),
                                    systemImage: "icloud.slash"
                                )
                            }

                            Divider()

                            Button(role: .destructive) {
                                pendingDeleteTag = tag
                            } label: {
                                Label(
                                    LumiPluginLocalization.string("Delete Tag", bundle: .module),
                                    systemImage: "tag.slash"
                                )
                            }
                        } label: {
                            Label(tag, systemImage: "tag")
                        }
                        .disabled(isOperationRunning)
                    }
                } label: {
                    Label(
                        LumiPluginLocalization.string("Manage Tags", bundle: .module),
                        systemImage: "tag.fill"
                    )
                }
            }

            Divider()

            if canUndo(commit) {
                Button(role: .destructive) {
                    historyError = nil
                    pendingUndo = commit
                } label: {
                    Label(
                        LumiPluginLocalization.string("Undo Commit", bundle: .module),
                        systemImage: "arrow.uturn.backward"
                    )
                }
                .disabled(
                    undoingHash != nil
                        || revertingHash != nil
                        || softResettingHash != nil
                        || mixedResettingHash != nil
                        || hardResettingHash != nil
                        || squashingHash != nil
                        || isTagOperationRunning
                )

                Divider()
            }

            Button(role: .destructive) {
                historyError = nil
                pendingRevert = commit
            } label: {
                Label(
                    LumiPluginLocalization.string("Revert This Commit", bundle: .module),
                    systemImage: "arrow.counterclockwise"
                )
            }
            .disabled(
                undoingHash != nil
                    || revertingHash != nil
                    || softResettingHash != nil
                    || mixedResettingHash != nil
                    || hardResettingHash != nil
                    || squashingHash != nil
                    || isTagOperationRunning
                    || commit.parentHashes.count > 1
            )

            if canSquash(commit) {
                Button {
                    historyError = nil
                    squashMessage = commit.message
                    pendingSquash = commit
                } label: {
                    Label(
                        LumiPluginLocalization.string("Squash to Here", bundle: .module),
                        systemImage: "arrow.triangle.merge"
                    )
                }
                .disabled(
                    undoingHash != nil
                        || revertingHash != nil
                        || softResettingHash != nil
                        || mixedResettingHash != nil
                        || hardResettingHash != nil
                        || squashingHash != nil
                        || isTagOperationRunning
                )

                Divider()
            }

            Menu {
                Button {
                    historyError = nil
                    pendingSoftReset = commit
                } label: {
                    Label(
                        LumiPluginLocalization.string("Soft Reset", bundle: .module),
                        systemImage: "text.badge.checkmark"
                    )
                }
                Button {
                    historyError = nil
                    pendingMixedReset = commit
                } label: {
                    Label(
                        LumiPluginLocalization.string("Mixed Reset", bundle: .module),
                        systemImage: "list.bullet.rectangle"
                    )
                }
                Button(role: .destructive) {
                    historyError = nil
                    pendingHardReset = commit
                } label: {
                    Label(
                        LumiPluginLocalization.string("Hard Reset", bundle: .module),
                        systemImage: "trash"
                    )
                }
            } label: {
                Label(
                    LumiPluginLocalization.string("Reset to Here", bundle: .module),
                    systemImage: "arrow.down.to.line"
                )
            }
            .disabled(
                undoingHash != nil
                    || revertingHash != nil
                    || softResettingHash != nil
                    || mixedResettingHash != nil
                    || hardResettingHash != nil
                    || squashingHash != nil
                    || isTagOperationRunning
            )
        }
    }

    // MARK: - Push Button & Popover

    private func pushButton(for commit: GitCommit) -> some View {
        AppIconButton(systemImage: "arrow.up.circle.fill", tint: .orange, size: .compact) {
            pushPopoverCommitHash = commit.hash
            pushError = nil
        }
        .help(LumiPluginLocalization.string("Click to push to remote", bundle: .module))
    }

    private func pushPopoverContent(for commit: GitCommit) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.orange)
                Text(LumiPluginLocalization.string("Push to Remote", bundle: .module))
                    .font(.headline)
                Spacer()
            }

            Divider()

            if isPushing {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(LumiPluginLocalization.string("Pushing...", bundle: .module))
                        .font(.body)
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text(LumiPluginLocalization.string("Current commit has not been pushed to remote", bundle: .module))
                            .font(.body)
                    }

                    if let error = pushError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(String(format: LumiPluginLocalization.string("Push failed: %@", bundle: .module), error))
                                .font(.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }

                    HStack(spacing: 12) {
                        AppButton(LumiPluginLocalization.string("Cancel", bundle: .module), style: .secondary, size: .small) {
                            pushPopoverCommitHash = nil
                            pushError = nil
                        }
                        .keyboardShortcut(.cancelAction)

                        AppButton(
                            pushError == nil ? "Push" : "Retry",
                            systemImage: pushError == nil ? "arrow.up.circle" : "arrow.clockwise",
                            style: .primary,
                            size: .small
                        ) {
                            performPush()
                        }
                        .keyboardShortcut(.defaultAction)
                    }

                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(width: 280, height: pushError != nil ? 200 : (isPushing ? 120 : 180))
    }

    private func performPush() {
        guard let project = projects.currentProject else { return }
        isPushing = true
        pushError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            do {
                _ = try git.push(in: url)
                await MainActor.run {
                    isPushing = false
                    pushPopoverCommitHash = nil
                    pushError = nil
                    // 推送成功后刷新列表
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    isPushing = false
                    pushError = error.localizedDescription
                }
            }
        }
    }

    private func performRevert(_ commit: GitCommit) {
        guard let project = projects.currentProject else { return }

        revertingHash = commit.hash
        historyError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.revertCommit(commit.hash, in: url)
            }
            await MainActor.run {
                revertingHash = nil
                switch result {
                case .success:
                    projects.notifyDataChanged()
                case .failure(let error):
                    historyError = error.localizedDescription
                }
            }
        }
    }

    private func performUndo(_ commit: GitCommit) {
        guard let project = projects.currentProject,
              let parentHash = commit.parentHashes.first else {
            historyError = LumiPluginLocalization.string(
                "Undoing the initial commit is not supported.",
                bundle: .module
            )
            return
        }

        undoingHash = commit.hash
        historyError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.undoCommit(commit.hash, parentHash: parentHash, in: url)
            }
            await MainActor.run {
                undoingHash = nil
                switch result {
                case .success:
                    projects.clearCommitSelection()
                    projects.notifyDataChanged()
                case .failure(let error):
                    historyError = error.localizedDescription
                }
            }
        }
    }

    private func performSoftReset(to commit: GitCommit) {
        guard let project = projects.currentProject,
              let expectedHead = commits.first?.hash else { return }

        softResettingHash = commit.hash
        historyError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.softReset(
                    to: commit.hash,
                    expectedHead: expectedHead,
                    in: url
                )
            }
            await MainActor.run {
                softResettingHash = nil
                switch result {
                case .success:
                    projects.clearCommitSelection()
                    projects.notifyDataChanged()
                case .failure(let error):
                    historyError = error.localizedDescription
                }
            }
        }
    }

    private func performMixedReset(to commit: GitCommit) {
        guard let project = projects.currentProject,
              let expectedHead = commits.first?.hash else { return }

        mixedResettingHash = commit.hash
        historyError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.mixedReset(
                    to: commit.hash,
                    expectedHead: expectedHead,
                    in: url
                )
            }
            await MainActor.run {
                mixedResettingHash = nil
                switch result {
                case .success:
                    projects.clearCommitSelection()
                    projects.notifyDataChanged()
                case .failure(let error):
                    historyError = error.localizedDescription
                }
            }
        }
    }

    private func performHardReset(to commit: GitCommit) {
        guard let project = projects.currentProject,
              let expectedHead = commits.first?.hash else { return }

        hardResettingHash = commit.hash
        historyError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.hardReset(
                    to: commit.hash,
                    expectedHead: expectedHead,
                    in: url
                )
            }
            await MainActor.run {
                hardResettingHash = nil
                switch result {
                case .success:
                    projects.clearCommitSelection()
                    projects.notifyDataChanged()
                case .failure(let error):
                    historyError = error.localizedDescription
                }
            }
        }
    }

    private func performSquash(to commit: GitCommit) {
        guard let project = projects.currentProject,
              let expectedHead = commits.first?.hash,
              let parentHash = commit.parentHashes.first else { return }

        let message = squashMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        squashingHash = commit.hash
        historyError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.squash(
                    to: commit.hash,
                    parentHash: parentHash,
                    expectedHead: expectedHead,
                    message: message,
                    in: url
                )
            }
            await MainActor.run {
                squashingHash = nil
                switch result {
                case .success:
                    projects.clearCommitSelection()
                    projects.notifyDataChanged()
                case .failure(let error):
                    historyError = error.localizedDescription
                }
            }
        }
    }

    private func performCreateTag(at commit: GitCommit) {
        guard let project = projects.currentProject else { return }
        let name = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        creatingTagHash = commit.hash
        tagError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.createLightweightTag(named: name, at: commit.hash, in: url)
            }
            await MainActor.run {
                creatingTagHash = nil
                switch result {
                case .success:
                    projects.notifyDataChanged()
                case .failure(let error):
                    tagError = error.localizedDescription
                }
            }
        }
    }

    private func performCreateAnnotatedTag(at commit: GitCommit) {
        guard let project = projects.currentProject else { return }
        let name = annotatedTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = annotatedTagMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !message.isEmpty else { return }

        creatingAnnotatedTagHash = commit.hash
        tagError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.createAnnotatedTag(
                    named: name,
                    at: commit.hash,
                    message: message,
                    in: url
                )
            }
            await MainActor.run {
                creatingAnnotatedTagHash = nil
                switch result {
                case .success:
                    projects.notifyDataChanged()
                case .failure(let error):
                    tagError = error.localizedDescription
                }
            }
        }
    }

    private func performDeleteTag(named name: String) {
        guard let project = projects.currentProject else { return }
        deletingTagName = name
        tagError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.deleteLocalTag(named: name, in: url)
            }
            await MainActor.run {
                deletingTagName = nil
                switch result {
                case .success:
                    projects.notifyDataChanged()
                case .failure(let error):
                    tagError = error.localizedDescription
                }
            }
        }
    }

    private func performPushTag(named name: String) {
        guard let project = projects.currentProject else { return }
        pushingTagName = name
        tagError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.pushTag(named: name, remote: "origin", in: url)
            }
            await MainActor.run {
                pushingTagName = nil
                switch result {
                case .success:
                    projects.notifyDataChanged()
                case .failure(let error):
                    tagError = error.localizedDescription
                }
            }
        }
    }

    private func performDeleteRemoteTag(named name: String) {
        guard let project = projects.currentProject else { return }
        deletingRemoteTagName = name
        tagError = nil
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.deleteRemoteTag(named: name, remote: "origin", in: url)
            }
            await MainActor.run {
                deletingRemoteTagName = nil
                switch result {
                case .success:
                    projects.notifyDataChanged()
                case .failure(let error):
                    tagError = error.localizedDescription
                }
            }
        }
    }

    private var isTagOperationRunning: Bool {
        creatingTagHash != nil
            || creatingAnnotatedTagHash != nil
            || deletingTagName != nil
            || pushingTagName != nil
            || deletingRemoteTagName != nil
    }

    private var isOperationRunning: Bool {
        undoingHash != nil
            || revertingHash != nil
            || softResettingHash != nil
            || mixedResettingHash != nil
            || hardResettingHash != nil
            || squashingHash != nil
            || isTagOperationRunning
    }

    private var shouldShowJumpToLatest: Bool {
        commits.count > 1 && (isShowingOldestPage || !isLatestCommitVisible)
    }

    private var shouldShowJumpToOldest: Bool {
        commits.count > 1
            && !isShowingOldestPage
            && hasScrolledDownEnough
            && !isOldestCommitVisible
    }

    private func jumpToLatestButton(using proxy: ScrollViewProxy) -> some View {
        HStack {
            Spacer(minLength: 0)
            AppIconButton(
                systemImage: "arrow.up.to.line",
                label: LumiPluginLocalization.string("Back to Latest Commit", bundle: .module),
                size: .compact
            ) {
                scrollToLatest(using: proxy)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .background(theme.surface)
        .borderBottom()
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func jumpToOldestButton(using proxy: ScrollViewProxy) -> some View {
        HStack {
            Spacer(minLength: 0)
            if isJumpingToOldest {
                ProgressView()
                    .controlSize(.small)
            } else {
                AppIconButton(
                    systemImage: "arrow.down.to.line",
                    label: LumiPluginLocalization.string("Jump to First Commit", bundle: .module),
                    size: .compact
                ) {
                    scrollToOldest(using: proxy)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .background(theme.surface)
        .borderTop()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func updateCommitScrollPosition(offset: CGFloat, maximumOffset: CGFloat) {
        let topTolerance: CGFloat = 8
        let isAtLatest = offset <= topTolerance
        let isAtOldest = maximumOffset <= topTolerance
            || maximumOffset - offset <= topTolerance

        isLatestCommitVisible = isAtLatest
        isOldestCommitVisible = isAtOldest
        hasScrolledDownEnough = offset >= jumpToOldestTriggerDistance
    }

    private func scrollToLatest(using proxy: ScrollViewProxy) {
        if isShowingOldestPage {
            commits = latestCommitSnapshot
            isShowingOldestPage = false
            oldestLoadedOffset = nil
            hasMoreCommits = latestCommitSnapshot.count == commitPageSize
            nextCommitOffset = latestCommitSnapshot.count
            isLatestCommitVisible = true
            isOldestCommitVisible = false
            hasScrolledDownEnough = false

            Task { @MainActor in
                await Task.yield()
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(CommitScrollAnchor.latest, anchor: .top)
                }
            }
            return
        }

        hasScrolledDownEnough = false
        withAnimation(.easeInOut(duration: 0.25)) {
            proxy.scrollTo(CommitScrollAnchor.latest, anchor: .top)
        }
    }

    /// 只加载历史末端一页，再滚动到其中最早的 commit。
    private func scrollToOldest(using proxy: ScrollViewProxy) {
        guard !isJumpingToOldest,
              !isLoading,
              let url = loadedProjectURL else { return }

        guard hasMoreCommits else {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(CommitScrollAnchor.oldest, anchor: .bottom)
            }
            return
        }

        isJumpingToOldest = true
        let token = loadToken
        Task { @MainActor in
            isLoading = true
            let result = await Task.detached(priority: .userInitiated) {
                Result {
                    let totalCount = try git.countCommits(in: url)
                    let offset = max(0, totalCount - commitPageSize)
                    let loaded = try git.loadCommits(
                        in: url,
                        limit: commitPageSize,
                        offset: offset
                    )
                    return (totalCount, loaded)
                }
            }.value

            guard token == loadToken, loadedProjectURL == url else {
                isLoading = false
                isJumpingToOldest = false
                return
            }

            switch result {
            case .success(let result):
                latestCommitSnapshot = Array(commits.prefix(commitPageSize))
                commits = result.1
                isShowingOldestPage = true
                oldestLoadedOffset = max(0, result.0 - result.1.count)
                hasMoreCommits = false
                nextCommitOffset = result.0
                isLatestCommitVisible = false
                isOldestCommitVisible = false
                hasScrolledDownEnough = false
                isLoading = false
                isJumpingToOldest = false
                Task { @MainActor in
                    await Task.yield()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(CommitScrollAnchor.oldest, anchor: .bottom)
                    }
                }
            case .failure(let error):
                isLoading = false
                isJumpingToOldest = false
                loadError = error.localizedDescription
            }
        }
    }

    private func canUndo(_ commit: GitCommit) -> Bool {
        commits.first?.hash == commit.hash
            && unpushedHashes.contains(commit.hash)
            && commit.tags.isEmpty
            && !commit.parentHashes.isEmpty
    }

    private func canSquash(_ commit: GitCommit) -> Bool {
        guard let index = commits.firstIndex(where: { $0.hash == commit.hash }),
              index >= 1,
              !commit.parentHashes.isEmpty else { return false }

        return commits.prefix(index + 1).allSatisfy {
            unpushedHashes.contains($0.hash)
        }
    }

    private func select(_ commit: GitCommit) {
        projects.selectCommit(commit)
    }

    /// 该行是否处于选中态（以 Provider 为单一权威来源）。
    private func isSelected(_ commit: GitCommit) -> Bool {
        projects.currentCommit?.hash == commit.hash
    }

    // MARK: - Time Formatting

    private static func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private static func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    // MARK: - Loading

    /// 当最后一条提交进入可见区域时，加载下一页历史并追加到当前列表。
    private func loadMoreIfNeeded(after commit: GitCommit) {
        guard commit.id == commits.last?.id,
              hasMoreCommits,
              !isLoading,
              let url = loadedProjectURL else { return }

        isLoading = true
        let token = loadToken
        let offset = nextCommitOffset
        Task.detached(priority: .userInitiated) {
            let result = Result {
                try git.loadCommits(
                    in: url,
                    limit: commitPageSize,
                    offset: offset
                )
            }
            await MainActor.run {
                guard token == loadToken, loadedProjectURL == url else { return }
                isLoading = false
                switch result {
                case .success(let loaded):
                    nextCommitOffset += loaded.count
                    hasMoreCommits = loaded.count == commitPageSize
                    guard !loaded.isEmpty else { return }

                    let existingHashes = Set(commits.map(\.hash))
                    let newCommits = loaded.filter { !existingHashes.contains($0.hash) }
                    commits.append(contentsOf: newCommits)
                case .failure(let error):
                    loadError = error.localizedDescription
                }
            }
        }
    }

    /// 在历史末端页向上滚动时，按页加载更接近最新提交的历史。
    ///
    /// 新页面插入到当前列表前方，并把原来的首条 commit 恢复到顶部，
    /// 避免分页完成时视图突然跳动。
    private func loadMoreTowardsLatestIfNeeded(
        when commit: GitCommit,
        using proxy: ScrollViewProxy
    ) {
        guard isShowingOldestPage,
              commit.id == commits.first?.id,
              !isLoading,
              let url = loadedProjectURL,
              let currentOffset = oldestLoadedOffset,
              currentOffset > 0 else { return }

        let nextOffset = max(0, currentOffset - commitPageSize)
        let pageLimit = currentOffset - nextOffset
        let previousFirstID = commit.id
        let token = loadToken
        isLoading = true

        Task { @MainActor in
            let result = await Task.detached(priority: .userInitiated) {
                Result {
                    try git.loadCommits(
                        in: url,
                        limit: pageLimit,
                        offset: nextOffset
                    )
                }
            }.value

            guard token == loadToken, loadedProjectURL == url else {
                isLoading = false
                return
            }

            isLoading = false
            switch result {
            case .success(let loaded):
                let existingHashes = Set(commits.map(\.hash))
                let newCommits = loaded.filter { !existingHashes.contains($0.hash) }
                commits.insert(contentsOf: newCommits, at: 0)
                oldestLoadedOffset = nextOffset

                if nextOffset == 0 {
                    isShowingOldestPage = false
                    oldestLoadedOffset = nil
                    nextCommitOffset = commits.count
                    hasMoreCommits = false
                }

                await Task.yield()
                withAnimation(.none) {
                    proxy.scrollTo(previousFirstID, anchor: .top)
                }
            case .failure(let error):
                loadError = error.localizedDescription
            }
        }
    }

    /// 项目变化时重新加载 commit 列表。切换项目时 Provider 内部已联动清空
    /// 选中状态（`ProjectManager` 保证选择属于当前项目）。
    ///
    /// `force` 为 true（如提交 / 推送后收到 `dataChanged`）时即使项目未变也重载，
    /// 以便展示新提交。
    private func reloadIfNeeded(force: Bool = false) {
        guard let project = projects.currentProject else {
            loadToken &+= 1
            if loadedProjectURL != nil {
                loadedProjectURL = nil
                commits = []
                latestCommitSnapshot = []
                isShowingOldestPage = false
                oldestLoadedOffset = nil
                unpushedHashes = []
                isLoading = false
                loadError = nil
                hasMoreCommits = true
                nextCommitOffset = 0
                animatedCommitHashes = []
            }
            isLatestCommitVisible = true
            isOldestCommitVisible = false
            hasScrolledDownEnough = false
            isJumpingToOldest = false
            return
        }
        if loadedProjectURL == project.url && !force { return }

        loadToken &+= 1
        let token = loadToken
        let isRefreshingExistingProject = loadedProjectURL == project.url
            && !commits.isEmpty
            && !isShowingOldestPage
        loadedProjectURL = project.url
        isLoading = true
        if !isRefreshingExistingProject {
            commits = []
            latestCommitSnapshot = []
            isShowingOldestPage = false
            oldestLoadedOffset = nil
            unpushedHashes = []
            animatedCommitHashes = []
            isLatestCommitVisible = true
            isOldestCommitVisible = false
            hasScrolledDownEnough = false
            isJumpingToOldest = false
        }
        hasMoreCommits = true
        nextCommitOffset = 0
        loadError = nil

        let url = project.url
        // 首屏提交列表和未推送状态都是后台读取，避免与 GitProcessRunner
        // 的 utility 管道读取形成 QoS 优先级反转。
        Task.detached(priority: .utility) {
            let commitsResult = Result {
                try git.loadCommits(
                    in: url,
                    limit: commitPageSize,
                    offset: 0
                )
            }
            // 获取未推送的 commit 哈希（无 upstream 时返回空集合）
            let unpushedResult = Result { try git.unpushedCommitHashes(in: url) }
            await MainActor.run {
                guard token == loadToken, loadedProjectURL == url else { return }
                isLoading = false
                switch commitsResult {
                case .success(let loaded):
                    nextCommitOffset = loaded.count
                    hasMoreCommits = loaded.count == commitPageSize
                    latestCommitSnapshot = Array(loaded.prefix(commitPageSize))
                    let insertedHashes = CommitListRefreshPolicy.insertedCommitHashes(
                        previous: commits,
                        current: loaded
                    )
                    let shouldAnimateInsertion = isRefreshingExistingProject && !insertedHashes.isEmpty
                    if shouldAnimateInsertion {
                        animatedCommitHashes = insertedHashes
                        withAnimation(.snappy(duration: 0.38)) {
                            commits = loaded
                        }
                        let animationToken = token
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            guard animationToken == loadToken else { return }
                            animatedCommitHashes = []
                        }
                    } else {
                        commits = loaded
                    }
                case .failure(let error):
                    loadError = error.localizedDescription
                }
                if case .success(let hashes) = unpushedResult {
                    unpushedHashes = hashes
                }
            }
        }
    }

    /// Provider 选中状态变化时刷新视图（驱动 SwiftUI 重算选中态高亮）。
    private func refreshSelectionState() {
        // 只需触发 body 重算；选中态以 Provider 为权威来源（isSelected 实时读取）。
    }
}

/// 读取 macOS 原生滚动容器的实时位置，避免依赖 LazyVStack 子视图只触发一次的 onAppear。
private struct CommitScrollOffsetReader: NSViewRepresentable {
    let onChange: @MainActor (CGFloat, CGFloat) -> Void

    func makeNSView(context: Context) -> CommitScrollOffsetTrackingView {
        CommitScrollOffsetTrackingView(onChange: onChange)
    }

    func updateNSView(_ nsView: CommitScrollOffsetTrackingView, context: Context) {
        nsView.onChange = onChange
        nsView.attachIfNeeded()
    }
}

@MainActor
private final class CommitScrollOffsetTrackingView: NSView {
    var onChange: @MainActor (CGFloat, CGFloat) -> Void

    private weak var observedScrollView: NSScrollView?
    private var observationTokens: [NSObjectProtocol] = []
    private var retryScheduled = false
    private var reportScheduled = false

    init(onChange: @escaping @MainActor (CGFloat, CGFloat) -> Void) {
        self.onChange = onChange
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            removeObservers()
            return
        }
        attachIfNeeded()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            removeObservers()
        }
        super.viewWillMove(toWindow: newWindow)
    }

    func attachIfNeeded() {
        guard let scrollView = enclosingScrollView() else {
            scheduleAttachRetry()
            return
        }

        guard observedScrollView !== scrollView else {
            scheduleReportScrollPosition()
            return
        }

        removeObservers()
        observedScrollView = scrollView

        let clipView = scrollView.contentView
        clipView.postsBoundsChangedNotifications = true
        clipView.postsFrameChangedNotifications = true
        scrollView.postsFrameChangedNotifications = true
        scrollView.documentView?.postsFrameChangedNotifications = true

        let notificationCenter = NotificationCenter.default
        observationTokens = [
            notificationCenter.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: clipView,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.scheduleReportScrollPosition()
                }
            },
            notificationCenter.addObserver(
                forName: NSView.frameDidChangeNotification,
                object: clipView,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.scheduleReportScrollPosition()
                }
            },
            notificationCenter.addObserver(
                forName: NSView.frameDidChangeNotification,
                object: scrollView.documentView,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.scheduleReportScrollPosition()
                }
            },
            notificationCenter.addObserver(
                forName: NSView.frameDidChangeNotification,
                object: scrollView,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.scheduleReportScrollPosition()
                }
            },
        ]

        scheduleReportScrollPosition()
    }

    private func enclosingScrollView() -> NSScrollView? {
        var ancestor = superview
        while let view = ancestor {
            if let scrollView = view as? NSScrollView {
                return scrollView
            }
            ancestor = view.superview
        }
        return nil
    }

    private func scheduleAttachRetry() {
        guard !retryScheduled else { return }
        retryScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            retryScheduled = false
            attachIfNeeded()
        }
    }

    private func reportScrollPosition() {
        guard let scrollView = observedScrollView else { return }
        let clipView = scrollView.contentView
        let viewportHeight = clipView.bounds.height
        let documentHeight = scrollView.documentView?.bounds.height ?? 0
        let maximumOffset = max(0, documentHeight - viewportHeight)
        let offset = min(max(0, clipView.bounds.origin.y), maximumOffset)
        onChange(offset, maximumOffset)
    }

    /// Defer callbacks originating from NSViewRepresentable updates until the
    /// current SwiftUI update pass has completed. Coalesce repeated layout
    /// notifications into one position report.
    private func scheduleReportScrollPosition() {
        guard !reportScheduled else { return }
        reportScheduled = true
        Task { @MainActor [weak self] in
            await Task.yield()
            guard let self else { return }
            reportScheduled = false
            reportScrollPosition()
        }
    }

    private func removeObservers() {
        let notificationCenter = NotificationCenter.default
        observationTokens.forEach(notificationCenter.removeObserver)
        observationTokens.removeAll()
        observedScrollView = nil
    }

}

/// Commit 刷新时的纯数据判断，供 UI 增量更新和测试复用。
enum CommitListRefreshPolicy {
    static func insertedCommitHashes(previous: [GitCommit], current: [GitCommit]) -> Set<String> {
        let previousHashes = Set(previous.map(\.hash))
        return Set(current.lazy.map(\.hash)).subtracting(previousHashes)
    }
}

/// 项目观察模型：订阅 `ProjectProviding` 的观察者事件，
/// 把变化转成 `@Published revision` 以驱动 SwiftUI 视图重算。
@MainActor
final class ProjectObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    @Published private(set) var lastEvent: ProjectProvidingEvent?
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] event in
            self?.lastEvent = event
            self?.revision += 1
        }
    }
}

/// Git 仓库监听观察模型：订阅 `GitRepositoryWatching` 的事件，
/// 把 .git 目录变化（HEAD / index / stash / refs）转成 `@Published revision`
/// 以驱动 SwiftUI 视图强制刷新。
///
/// 当外部修改仓库（如终端 `git commit` / `git checkout` / 其他工具改仓库）时，
/// FSEventStream 监听到 .git 目录变化，`GitRepositoryWatching` 广播事件，
/// 本模型接收并触发视图刷新，从而能感知外部修改。
@MainActor
final class GitRepositoryWatchObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    @Published private(set) var lastEvent: GitRepositoryWatchingEvent?
    private var handle: (any GitRepositoryWatchingObserverHandle)?

    init(gitWatch: (any GitRepositoryWatching)?) {
        guard let gitWatch else { return }
        handle = gitWatch.addObserver { [weak self] event in
            self?.lastEvent = event
            self?.revision += 1
        }
    }
}
