import KitGit
import LumiUI
import ProviderGitRepositoryWatch
import ProviderProjects
import SwiftUI

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
    let projects: any ProjectProviding
    let gitWatch: (any GitRepositoryWatching)?
    @LumiTheme private var theme
    @StateObject private var projectObservation: ProjectObservationModel
    @StateObject private var gitWatchObservation: GitRepositoryWatchObservationModel

    @State private var commits: [GitCommit] = []
    @State private var unpushedHashes: Set<String> = []
    @State private var isLoading = false
    @State private var loadedProjectURL: URL?
    @State private var loadError: String?

    // Push 状态
    @State private var pushPopoverCommitHash: String?
    @State private var isPushing = false
    @State private var pushError: String?

    init(projects: any ProjectProviding, gitWatch: (any GitRepositoryWatching)? = nil) {
        self.projects = projects
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
        if projects.currentProject == nil {
            AppEmptyState(
                icon: "folder",
                title: "Select a Project",
                description: "Choose a project from the sidebar to see its commits."
            )
        } else if isLoading && commits.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let loadError {
            AppEmptyState(
                icon: "exclamationmark.triangle",
                title: "Unable to Load Commits",
                description: loadError
            )
        } else if commits.isEmpty {
            AppEmptyState(
                icon: "clock",
                title: "No Commits",
                description: "This repository has no commits yet."
            )
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(commits) { commit in
                        commitRow(commit)
                        if commit.id != commits.last?.id {
                            AppDivider()
                        }
                    }
                }
                .padding(.vertical, 4)
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
                    authorBadge(commit.author)
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
        .popover(
            isPresented: Binding(
                get: { pushPopoverCommitHash == commit.hash },
                set: { if !$0 { pushPopoverCommitHash = nil; pushError = nil } }
            )
        ) {
            pushPopoverContent(for: commit)
        }
    }

    // MARK: - Push Button & Popover

    private func pushButton(for commit: GitCommit) -> some View {
        AppIconButton(systemImage: "arrow.up.circle.fill", tint: .orange, size: .compact) {
            pushPopoverCommitHash = commit.hash
            pushError = nil
        }
        .help("Click to push to remote")
    }

    private func pushPopoverContent(for commit: GitCommit) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.orange)
                Text("Push to Remote")
                    .font(.headline)
                Spacer()
            }

            Divider()

            if isPushing {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Pushing...")
                        .font(.body)
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("Current commit has not been pushed to remote")
                            .font(.body)
                    }

                    if let error = pushError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Push failed: \(error)")
                                .font(.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }

                    HStack(spacing: 12) {
                        AppButton("Cancel", style: .secondary, size: .small) {
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
                try GitRemoteOperation.push(in: url)
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

    private func select(_ commit: GitCommit) {
        projects.selectCommit(commit)
    }

    /// 该行是否处于选中态（以 Provider 为单一权威来源）。
    private func isSelected(_ commit: GitCommit) -> Bool {
        projects.currentCommit?.hash == commit.hash
    }

    /// 作者头像徽标（LumiUI AppAvatar，基于名字稳定取色，hover 有动效）。
    private func authorBadge(_ author: String) -> some View {
        let initial = author.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? "?"
        let hue = Double(abs(author.hashValue % 360)) / 360.0
        let color = Color(hue: hue, saturation: 0.5, brightness: 0.72)
        return ZStack {
            AppAvatar(
                systemImage: "\(initial.uppercased())",
                tint: color,
                backgroundTint: color.opacity(0.15),
                size: 18
            )
        }
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

    /// 项目变化时重新加载 commit 列表。切换项目时 Provider 内部已联动清空
    /// 选中状态（`ProjectManager` 保证选择属于当前项目）。
    ///
    /// `force` 为 true（如提交 / 推送后收到 `dataChanged`）时即使项目未变也重载，
    /// 以便展示新提交。
    private func reloadIfNeeded(force: Bool = false) {
        guard let project = projects.currentProject else {
            if loadedProjectURL != nil {
                loadedProjectURL = nil
                commits = []
                unpushedHashes = []
                isLoading = false
                loadError = nil
            }
            return
        }
        if loadedProjectURL == project.url && !force { return }

        loadedProjectURL = project.url
        isLoading = true
        commits = []
        unpushedHashes = []
        loadError = nil

        let url = project.url
        Task.detached(priority: .userInitiated) {
            let commitsResult = Result { try GitCommitLoader.loadCommits(in: url) }
            // 获取未推送的 commit 哈希（无 upstream 时返回空集合）
            let unpushedResult = Result { try GitCommitLoader.unpushedCommitHashes(in: url) }
            await MainActor.run {
                isLoading = false
                switch commitsResult {
                case .success(let loaded):
                    commits = loaded
                case .failure(let error):
                    loadError = (error as? GitCommitLoaderError)?.localizedDescription
                        ?? error.localizedDescription
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
