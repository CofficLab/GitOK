import KitGit
import LumiUI
import ProviderCommit
import ProviderProjects
import SwiftUI

/// Commit 列表 Rail 视图：显示当前打开项目的提交历史。
///
/// 作为 Rail 注入根布局（位于侧边栏右侧、内容区左侧）。订阅
/// `ProjectProviding` 的观察者事件；`currentProject` 变化时异步读取
/// 该仓库的 commit 列表（后台线程执行 git CLI，主线程更新）。
///
/// 同时订阅 `CommitDetailProviding`（Lumi 式"单 Provider 多处消费"）：
/// - 行点击把选中的 commit 写入 Provider，主内容区（PluginCommitDetail）
///   据此展示该 commit 的变动；
/// - 本视图据 Provider 的选中状态高亮当前行；
/// - 切换项目时联动清空选择，避免旧项目的选中残留。
///
/// 视觉对齐旧版 GitOK 的 commit 行布局（message / 作者 + 相对时间 /
/// 完整日期），并使用 LumiUI 组件（AppToolbarContainer / AppListRow /
/// AppEmptyState / AppDivider）保证与整体设计语言一致。
struct CommitRailView: View {
    let projects: any ProjectProviding
    let detail: any CommitDetailProviding
    @LumiTheme private var theme
    @StateObject private var projectObservation: ProjectObservationModel
    @StateObject private var detailObservation: CommitDetailObservationModel

    @State private var commits: [GitCommit] = []
    @State private var isLoading = false
    @State private var loadedProjectURL: URL?
    @State private var loadError: String?

    init(projects: any ProjectProviding, detail: any CommitDetailProviding) {
        self.projects = projects
        self.detail = detail
        _projectObservation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
        _detailObservation = StateObject(wrappedValue: CommitDetailObservationModel(detail: detail))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            AppDivider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color(nsColor: .underPageBackgroundColor)
        }
        .onReceive(projectObservation.$revision) { _ in reloadIfNeeded() }
        // dataChanged（提交/推送后）→ 即使项目未变也强制刷新列表。
        .onReceive(projectObservation.$lastEvent) { event in
            if case .dataChanged = event {
                reloadIfNeeded(force: true)
            }
        }
        // 选中 commit 变化（可能来自本列表，也可能来自其它消费方）→ 刷新选中态。
        .onReceive(detailObservation.$revision) { _ in refreshSelectionState() }
        .onAppear { reloadIfNeeded() }
    }

    // MARK: - Header

    private var header: some View {
        AppToolbarContainer(
            height: 36,
            padding: EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
        ) {
            HStack(spacing: 8) {
                AppToolbarTitleLabel(icon: "clock", title: "Commits") {
                    if let project = projects.currentProject {
                        Text(project.title)
                            .font(DesignTokens.Typography.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer(minLength: 8)
            }
        }
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
                                .padding(.leading, 12)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Commit Row

    private func commitRow(_ commit: GitCommit) -> some View {
        AppListRow(isSelected: isSelected(commit), action: { select(commit) }) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(commit.message)
                            .font(DesignTokens.Typography.subheadline.weight(.medium))
                            .foregroundStyle(theme.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 8)
                        AppTag(commit.shortHash, systemImage: "arrow.triangle.branch")
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
                .padding(.vertical, 2)
            }
        }
    }

    private func select(_ commit: GitCommit) {
        guard let project = projects.currentProject else { return }
        detail.selectCommit(commit, in: project.url)
    }

    /// 该行是否处于选中态（以 Provider 为单一权威来源）。
    private func isSelected(_ commit: GitCommit) -> Bool {
        detail.selectedCommit?.hash == commit.hash
    }

    /// 作者首字母小徽标（基于名字稳定取色）。
    private func authorBadge(_ author: String) -> some View {
        let initial = author.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? "?"
        let hue = Double(abs(author.hashValue % 360)) / 360.0
        let color = Color(hue: hue, saturation: 0.45, brightness: 0.8)
        return ZStack {
            Circle().fill(color.opacity(0.18))
            Text(initial.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: 16, height: 16)
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

    /// 项目变化时重新加载 commit 列表；切换项目时联动清空 Provider 的选中状态，
    /// 避免旧项目的选中 commit 残留在主内容区。
    ///
    /// `force` 为 true（如提交 / 推送后收到 `dataChanged`）时即使项目未变也重载，
    /// 以便展示新提交。
    private func reloadIfNeeded(force: Bool = false) {
        guard let project = projects.currentProject else {
            if loadedProjectURL != nil {
                loadedProjectURL = nil
                commits = []
                isLoading = false
                loadError = nil
                detail.clearSelection()
            }
            return
        }
        if loadedProjectURL == project.url && !force { return }

        // 项目确实发生了变化：清空旧选中。
        if loadedProjectURL != nil {
            detail.clearSelection()
        }

        loadedProjectURL = project.url
        isLoading = true
        commits = []
        loadError = nil

        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result { try GitCommitLoader.loadCommits(in: url) }
            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let loaded):
                    commits = loaded
                case .failure(let error):
                    loadError = (error as? GitCommitLoaderError)?.localizedDescription
                        ?? error.localizedDescription
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

/// Commit 详情观察模型：订阅 `CommitDetailProviding` 的观察者事件，
/// 把变化转成 `@Published revision` 以驱动 SwiftUI 视图重算（选中行高亮）。
@MainActor
final class CommitDetailObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any CommitDetailObserverHandle)?

    init(detail: any CommitDetailProviding) {
        handle = detail.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
