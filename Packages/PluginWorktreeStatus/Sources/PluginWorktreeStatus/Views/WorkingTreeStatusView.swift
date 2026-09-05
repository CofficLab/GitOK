import KitGit
import LumiUI
import ProviderGitRepositoryWatch
import ProviderProjects
import SwiftUI

private func loc(_ key: String) -> String {
    WorktreeStatusLocalization.string(key, bundle: .module)
}

/// 工作区状态 Rail 区块视图：复刻旧版 GitOK 的 commit 列表顶部状态头。
///
/// 视觉：72pt 高，左侧两行文字（标题+副标题），右侧蓝色同步按钮
/// （显示 ↑/↓ 计数，点击执行 fetch/pull/push 主操作）。
///
/// 功能：未提交更改计数、未推送/未拉取计数、远程跟踪状态、
/// fetch/pull/push 操作、活动状态显示。点击状态区域时清除当前选中
/// commit（`projects.clearCommitSelection()`），触发详情区展示工作区变动文件。
///
/// 选中态（对齐旧版 WorkingStateSummaryView）：未选中任何 commit 时工作区
/// 处于选中态，背景高亮（`theme.appListRowSelectedBackground` + 主色描边）；
/// 用户点选 commit 行后取消选中，背景恢复 `theme.surface`。
struct WorkingTreeStatusView: View {
    let projects: any ProjectProviding
    let gitWatch: (any GitRepositoryWatching)?
    let syncFailureCenter: WorktreeSyncFailureCenter?
    @LumiTheme private var theme
    @StateObject private var projectObservation: ProjectObservationModel
    @StateObject private var gitWatchObservation: GitRepositoryWatchObservationModel

    // 工作区状态
    @State private var changeCount: Int = 0
    @State private var isClean: Bool = true
    @State private var branch: String?

    // 远程跟踪状态
    @State private var trackingStatus = GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)

    // 活动状态
    @State private var activityStatus: String?
    @State private var isFetching = false
    @State private var isPulling = false
    @State private var isPushing = false

    @State private var loadedProjectURL: URL?
    @State private var isLoading = false

    init(
        projects: any ProjectProviding,
        gitWatch: (any GitRepositoryWatching)? = nil,
        syncFailureCenter: WorktreeSyncFailureCenter? = nil
    ) {
        self.projects = projects
        self.gitWatch = gitWatch
        self.syncFailureCenter = syncFailureCenter
        _projectObservation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
        _gitWatchObservation = StateObject(wrappedValue: GitRepositoryWatchObservationModel(gitWatch: gitWatch))
    }

    var body: some View {
        Group {
            if projects.currentProject != nil {
                summaryRow
            }
        }
        .onReceive(projectObservation.$revision) { _ in reloadIfNeeded() }
        .onReceive(projectObservation.$lastEvent) { event in
            if case .dataChanged = event {
                reloadIfNeeded(force: true)
            }
        }
        .onReceive(gitWatchObservation.$revision) { _ in
            // .git 目录变化（HEAD / index / stash / refs 任一变化）→ 强制刷新工作区状态
            reloadIfNeeded(force: true)
        }
        .onAppear { reloadIfNeeded() }
    }

    // MARK: - Summary Row (复刻旧版 WorkingStateSummaryView，72pt 高)

    /// 工作区是否处于选中态（对齐旧版 `isWorkingStateSelected`）：
    /// 当前项目下未选中任何 commit 即视为选中工作区。
    private var isSelected: Bool {
        projects.currentCommit == nil
    }

    private var summaryRow: some View {
        HStack(spacing: 14) {
            statusText
            Spacer(minLength: 8)
            syncButton
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
        .frame(maxWidth: .infinity)
        .background {
            // 选中态背景高亮（与 commit 行 AppListRow 选中样式一致）。
            if isSelected {
                theme.appListRowSelectedBackground
            } else {
                theme.surface
            }
        }
        .overlay {
            if isSelected {
                Rectangle()
                    .stroke(theme.primary.opacity(0.3), lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // 点击工作区状态条 → 清除当前选中 commit，触发详情区展示工作区变动文件。
            projects.clearCommitSelection()
        }
    }

    // MARK: - Status Text (左侧两行文字)

    private var statusText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(statusTitle)
                .font(DesignTokens.Typography.body.weight(.semibold))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)

            Text(statusSubtitle)
                .font(DesignTokens.Typography.caption1.weight(.medium))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    private var statusTitle: String {
        if let activityStatus {
            return activityStatus
        }
        if isClean {
            return loc("Working Tree Clean")
        } else {
            return loc("Changes Pending")
        }
    }

    private var statusSubtitle: String {
        if !isClean {
            return String(format: loc("(%lld) Uncommitted"), changeCount)
        }
        if trackingStatus.hasUpstream, trackingStatus.behind > 0 {
            return String(format: loc("%lld remote commits available to pull"), trackingStatus.behind)
        }
        return loc("All Changes Committed")
    }

    // MARK: - Sync Button (右侧蓝色同步按钮，复刻旧版 WorkspaceSyncButton)

    @ViewBuilder
    private var syncButton: some View {
        let isWorking = isFetching || isPulling || isPushing
        Button(action: performPrimaryAction) {
            HStack(spacing: 6) {
                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: primaryActionIcon)
                        .font(.system(size: 13, weight: .semibold))
                }
                if let badge = syncBadgeText {
                    Text(badge)
                        .font(DesignTokens.Typography.caption1.weight(.semibold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
        .help(primaryActionHelp)
        .fixedSize(horizontal: true, vertical: false)
    }

    private enum SyncPrimaryAction {
        case fetch
        case pull
        case push
    }

    private var primaryAction: SyncPrimaryAction {
        if trackingStatus.hasUpstream, trackingStatus.behind > 0 {
            return .pull
        }
        if trackingStatus.hasUpstream, trackingStatus.ahead == 0 {
            return .fetch
        }
        return .push
    }

    private var primaryActionIcon: String {
        switch primaryAction {
        case .fetch: return "arrow.clockwise"
        case .pull: return "arrow.down"
        case .push: return "arrow.up"
        }
    }

    private var primaryActionHelp: String {
        switch primaryAction {
        case .fetch: return loc("Fetch from remote")
        case .pull: return loc("Pull from remote")
        case .push:
            return trackingStatus.hasUpstream ? loc("Push to remote") : loc("Publish branch")
        }
    }

    private var syncBadgeText: String? {
        guard trackingStatus.hasUpstream else { return nil }
        if trackingStatus.ahead > 0, trackingStatus.behind > 0 {
            return "↑\(trackingStatus.ahead) ↓\(trackingStatus.behind)"
        }
        if trackingStatus.ahead > 0 {
            return "↑\(trackingStatus.ahead)"
        }
        if trackingStatus.behind > 0 {
            return "↓\(trackingStatus.behind)"
        }
        return nil
    }

    private func performPrimaryAction() {
        switch primaryAction {
        case .fetch: performFetch()
        case .pull: performPull()
        case .push: performPush()
        }
    }

    // MARK: - Remote Operations

    private func performFetch() {
        guard let project = projects.currentProject else { return }
        isFetching = true
        activityStatus = loc("Fetching")
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result { try GitRemoteOperation.fetch(in: url) }
            await MainActor.run {
                isFetching = false
                activityStatus = nil
                switch result {
                case .success:
                    reloadIfNeeded(force: true)
                case let .failure(error):
                    presentSyncFailure(operation: "Fetch", error: error)
                }
            }
        }
    }

    private func performPull() {
        guard let project = projects.currentProject else { return }
        isPulling = true
        activityStatus = loc("Pulling")
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result { try GitRemoteOperation.pull(in: url) }
            await MainActor.run {
                isPulling = false
                activityStatus = nil
                switch result {
                case .success:
                    reloadIfNeeded(force: true)
                case let .failure(error):
                    presentSyncFailure(operation: "Pull", error: error)
                }
            }
        }
    }

    private func performPush() {
        guard let project = projects.currentProject else { return }
        isPushing = true
        activityStatus = loc("Pushing")
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result { try GitCommitOperation.push(in: url) }
            await MainActor.run {
                isPushing = false
                activityStatus = nil
                switch result {
                case .success:
                    reloadIfNeeded(force: true)
                case let .failure(error):
                    presentSyncFailure(operation: "Push", error: error)
                }
            }
        }
    }

    /// 同步失败进入持久化的根视图错误面板，避免 Toast 自动消失或截断关键信息。
    @MainActor
    private func presentSyncFailure(operation: String, error: Error) {
        syncFailureCenter?.present(
            operation: loc("\(operation) failed"),
            message: error.localizedDescription
        )
        reloadIfNeeded(force: true)
    }

    // MARK: - Loading

    /// 项目变化时重新加载工作区状态和远程跟踪状态；force 为 true 时强制刷新。
    private func reloadIfNeeded(force: Bool = false) {
        guard let project = projects.currentProject else {
            loadedProjectURL = nil
            isClean = true
            changeCount = 0
            branch = nil
            trackingStatus = GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
            isLoading = false
            return
        }
        if loadedProjectURL == project.url && !force { return }

        loadedProjectURL = project.url
        isLoading = true

        let url = project.url
        Task.detached(priority: .userInitiated) {
            let statusResult = Result { try GitStatusLoader.loadStatus(in: url) }
            let tracking = GitRefReader.remoteTrackingStatus(in: url)
            await MainActor.run {
                isLoading = false
                if case .success(let loaded) = statusResult {
                    isClean = loaded.isClean
                    changeCount = loaded.changeCount
                    branch = loaded.branch
                }
                trackingStatus = tracking
            }
        }
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
/// 当外部修改仓库（如终端 `git stash` / `git checkout` / 其他工具改仓库）时，
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
