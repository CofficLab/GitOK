import KitGit
import LumiUI
import ProviderGitRepositoryWatch
import ProviderGit
import ProviderGitConflictResolver
import ProviderProjects
import ProviderToast
import SwiftUI

private func loc(_ key: String) -> String {
    WorktreeStatusLocalization.string(key, bundle: .module)
}

private extension GitRemoteOperation.SyncStep {
    var localizationKey: String {
        switch self {
        case .fetch: "Fetch failed"
        case .merge: "Merge failed"
        case .push: "Push failed"
        }
    }
}

/// The two intentional actions represented by the compact rail control.
/// Keeping this mapping separate from the view makes the button's visual state
/// deterministic and easy to cover without reaching into SwiftUI state.
enum WorktreeStatusActionMode: Equatable {
    case publish
    case synchronize

    static func resolve(hasUpstream: Bool) -> Self {
        hasUpstream ? .synchronize : .publish
    }
}

enum WorktreeSyncBadgeFormatter {
    static func text(ahead: Int, behind: Int, hasUpstream: Bool) -> String? {
        guard hasUpstream else { return nil }
        if ahead > 0, behind > 0 {
            return "↑\(ahead) ↓\(behind)"
        }
        if ahead > 0 {
            return "↑\(ahead)"
        }
        if behind > 0 {
            return "↓\(behind)"
        }
        return nil
    }
}

/// 工作区状态 Rail 区块视图：复刻旧版 GitOK 的 commit 列表顶部状态头。
///
/// 视觉：72pt 高，左侧两行文字（标题+副标题），右侧主题色 Branch Pulse 按钮
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
    let git: any GitProviding
    let gitWatch: (any GitRepositoryWatching)?
    let toast: (any ToastProviding)?
    let requestConflictResolution: @MainActor () -> Void
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
    @State private var isSynchronizing = false
    @State private var isPushing = false

    @State private var loadedProjectURL: URL?
    @State private var isLoading = false

    init(
        projects: any ProjectProviding,
        git: any GitProviding,
        gitWatch: (any GitRepositoryWatching)? = nil,
        toast: (any ToastProviding)? = nil,
        requestConflictResolution: @escaping @MainActor () -> Void = {}
    ) {
        self.projects = projects
        self.git = git
        self.gitWatch = gitWatch
        self.toast = toast
        self.requestConflictResolution = requestConflictResolution
        _projectObservation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
        _gitWatchObservation = StateObject(wrappedValue: GitRepositoryWatchObservationModel(gitWatch: gitWatch))
    }

    var body: some View {
        Group {
            if let project = projects.currentProject,
               FileManager.default.fileExists(atPath: project.url.path) {
                summaryRow
            }
        }
        .onReceive(projectObservation.$lastEvent) { event in
            guard let event else { return }
            if case .dataChanged = event {
                reloadIfNeeded(force: true)
            } else {
                reloadIfNeeded()
            }
        }
        .onReceive(gitWatchObservation.$lastEvent) { event in
            guard event != nil else { return }
            // 仓库或工作区变化 → 强制刷新工作区状态；后台刷新不切换 loading UI。
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
        WorktreeActionButton(
            mode: primaryActionMode,
            badge: syncBadgeText,
            isLoading: isLoading,
            activity: activityStatus,
            action: performPrimaryAction
        )
        .disabled(isSynchronizing || isPushing || isLoading)
        .help(primaryActionHelp)
    }

    private var primaryActionMode: WorktreeStatusActionMode {
        WorktreeStatusActionMode.resolve(hasUpstream: trackingStatus.hasUpstream)
    }

    private var primaryActionHelp: String {
        trackingStatus.hasUpstream ? loc("Synchronize with remote") : loc("Publish branch")
    }

    private var syncBadgeText: String? {
        WorktreeSyncBadgeFormatter.text(
            ahead: trackingStatus.ahead,
            behind: trackingStatus.behind,
            hasUpstream: trackingStatus.hasUpstream
        )
    }

    private func performPrimaryAction() {
        if let project = projects.currentProject,
           git.hasConflictOperation(in: project.url) {
            // 合并/Cherry-pick 已经在进行时，工作区按钮的语义应变成
            // “继续处理冲突”，不能再次发起同步。
            requestConflictResolution()
            reloadIfNeeded(force: true)
            return
        }
        if trackingStatus.hasUpstream {
            performSynchronize()
        } else {
            performPush()
        }
    }

    // MARK: - Remote Operations

    private func performSynchronize() {
        guard let project = projects.currentProject else { return }
        isSynchronizing = true
        activityStatus = loc("Synchronizing")
        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result { try git.synchronize(in: url) }
            await MainActor.run {
                isSynchronizing = false
                activityStatus = nil
                switch result {
                case .success:
                    reloadIfNeeded(force: true)
                case let .failure(error):
                    presentSyncFailure(error: error, repository: url)
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
            let result = Result { try git.push(in: url) }
            await MainActor.run {
                isPushing = false
                activityStatus = nil
                switch result {
                case .success:
                    reloadIfNeeded(force: true)
                case let .failure(error):
                    presentSyncFailure(
                        operation: loc("Push failed"),
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    /// 同步失败进入公共 Toast 提供者的持久化错误面板，避免普通 Toast
    /// 自动消失或截断关键信息。
    @MainActor
    private func presentSyncFailure(error: Error, repository: URL) {
        let operation: String
        let message: String
        if let syncError = error as? GitRemoteOperation.SyncError {
            // Merge 冲突由 GitConflictResolverPlugin 接管并自动打开冲突面板；
            // 不再叠加阻断层，避免把可操作的冲突解决 UI 盖住。
            if case .merge = syncError.step,
               git.hasConflictOperation(in: repository) {
                reloadIfNeeded(force: true)
                requestConflictResolution()
                return
            }
            operation = loc(syncError.step.localizationKey)
            message = syncError.message
        } else {
            operation = loc("Sync failed")
            message = error.localizedDescription
        }
        presentSyncFailure(operation: operation, message: message)
    }

    @MainActor
    private func presentSyncFailure(operation: String, message: String) {
        toast?.presentError(title: operation, message: message)
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
        let projectChanged = loadedProjectURL != project.url
        if !projectChanged, !force { return }

        loadedProjectURL = project.url
        // 只有首次加载或切换项目时才显示 loading。监听器触发的后台刷新
        // 保留当前按钮内容，避免每次文件事件都闪成 loading 动画。
        if projectChanged {
            isLoading = true
        }

        let url = project.url
        guard FileManager.default.fileExists(atPath: url.path) else {
            isLoading = false
            isClean = false
            changeCount = 0
            branch = nil
            trackingStatus = GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
            return
        }

        // GitProcessRunner 是同步 CLI 调用；工作区状态属于后台刷新，使用
        // utility 优先级可避免高优先级 Swift 任务等待运行器的 stderr 读取队列。
        Task.detached(priority: .utility) {
            let statusResult = Result { try git.loadStatus(in: url) }
            let tracking = git.remoteTrackingStatus(in: url)
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

// MARK: - Branch Pulse Button

/// A compact, theme-aware primary action control for the worktree rail.
///
/// The button stays icon-only to fit the narrow rail. It expands only when a
/// remote delta badge is present. Its branch mark and orbit loader are drawn
/// locally instead of using the system button/progress treatment.
private struct WorktreeActionButton: View {
    let mode: WorktreeStatusActionMode
    let badge: String?
    let isLoading: Bool
    let activity: String?
    let action: () -> Void

    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isHovered = false

    private var isBusy: Bool { activity != nil }

    var body: some View {
        Button(action: action) {
            buttonContent
            .foregroundStyle(actionColor)
            .padding(.horizontal, 10)
            .frame(width: buttonWidth, height: 34)
            .background(buttonBackground)
            .overlay(buttonBorder)
            .clipShape(Capsule())
            .shadow(
                color: actionColor.opacity(isHovered ? 0.18 : 0.10),
                radius: isHovered ? 7 : 3,
                y: 1
            )
            .scaleEffect(isHovered && motionPreference.allowsMotion ? 1.015 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            LumiMotion.animate(
                LumiMotion.enabled(LumiMotion.hover, preference: motionPreference)
            ) {
                isHovered = hovering
            }
        }
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(badge ?? "")
    }

    private var buttonWidth: CGFloat {
        if isLoading || isBusy { return 36 }
        guard let badge else { return 36 }
        return badge.contains(" ") ? 82 : 58
    }

    /// The row uses `primary` for the selected workspace; the action uses the
    /// separate informational accent so remote work reads as a different
    /// visual layer.
    private var actionColor: Color {
        theme.info
    }

    @ViewBuilder
    private var buttonContent: some View {
        if isLoading || isBusy {
            WorktreeOrbitLoader()
        } else if badge != nil {
            badgeView
        } else {
            WorktreePrimaryActionIcon(mode: mode)
        }
    }

    private var accessibilityTitle: String {
        if isLoading && !isBusy {
            return loc("Loading")
        }
        if let activity {
            return activity
        }
        return mode == .publish ? loc("Publish branch") : loc("Synchronize with remote")
    }

    @ViewBuilder
    private var badgeView: some View {
        if let badge, !isLoading, !isBusy {
            if badge.hasPrefix("↑"), !badge.contains(" ") {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up")
                    Text(String(badge.dropFirst()))
                }
                .font(.system(size: 12, weight: .bold, design: .monospaced))
            } else if badge.hasPrefix("↓"), !badge.contains(" ") {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.down")
                    Text(String(badge.dropFirst()))
                }
                .font(.system(size: 12, weight: .bold, design: .monospaced))
            } else {
                Text(badge)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .lineLimit(1)
            }
        }
    }

    private var buttonBackground: some View {
        Capsule(style: .continuous)
            .fill(actionColor.opacity(isHovered ? 0.18 : 0.11))
    }

    private var buttonBorder: some View {
        Capsule(style: .continuous)
            .stroke(actionColor.opacity(isHovered ? 0.34 : 0.18), lineWidth: 0.75)
    }
}

/// Large, immediately recognizable action glyph. Remote counts remain a
/// secondary badge so the direction itself is the visual protagonist.
private struct WorktreePrimaryActionIcon: View {
    let mode: WorktreeStatusActionMode

    var body: some View {
        Image(systemName: mode == .publish ? "arrow.up" : "arrow.triangle.2.circlepath")
            .font(.system(size: 19, weight: .bold))
        .frame(width: 20, height: 20)
    }
}

/// Theme-colored orbit loader. The center stays recognizable as a sync mark
/// while the outer sweep communicates that the remote operation is active.
private struct WorktreeOrbitLoader: View {
    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.info.opacity(0.20), lineWidth: 1)

            Circle()
                .trim(from: 0.08, to: 0.76)
                .stroke(
                    AngularGradient(
                        colors: [
                            theme.info,
                            theme.primarySecondary.opacity(0.75),
                            theme.info.opacity(0.25),
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                )
                .rotationEffect(.degrees(rotation - 90))

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.info)
        }
        .frame(width: 20, height: 20)
        .animation(
            motionPreference.allowsMotion
                ? .linear(duration: 1.15).repeatForever(autoreverses: false)
                : nil,
            value: rotation
        )
        .onAppear {
            guard motionPreference.allowsMotion else { return }
            rotation = 360
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
