import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 工作区状态 Rail 区块视图：显示当前项目的工作区状态。
///
/// 作为 Rail 的纵向区块（固定高度）注入，位于 commit 列表上方。
/// 订阅 `ProjectProviding` 的观察者事件；`currentProject` 变化时异步
/// 读取该仓库的 `git status`（后台线程执行 git CLI，主线程更新）。
///
/// 视觉与旧版 GitOK 的 commit 列表顶部状态头一致：干净时绿勾 +
/// "Working Tree Clean"，有变更时橙/红色计数 + "Uncommitted Changes"，
/// 右侧附当前分支名。
struct WorkingTreeStatusView: View {
    let projects: any ProjectProviding
    @LumiTheme private var theme
    @StateObject private var projectObservation: ProjectObservationModel

    @State private var status: GitWorktreeStatus?
    @State private var isLoading = false
    @State private var loadedProjectURL: URL?

    init(projects: any ProjectProviding) {
        self.projects = projects
        _projectObservation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    var body: some View {
        Group {
            if projects.currentProject != nil {
                statusRow
            }
        }
        .onReceive(projectObservation.$revision) { _ in reloadIfNeeded() }
        // dataChanged（提交/推送后）→ 强制刷新工作区状态。
        .onReceive(projectObservation.$lastEvent) { event in
            if case .dataChanged = event {
                reloadIfNeeded(force: true)
            }
        }
        .onAppear { reloadIfNeeded() }
    }

    // MARK: - Status Row

    /// 工作区状态行：干净（绿勾 + "Working Tree Clean"）或未提交变更计数。
    /// 右侧附当前分支名（对齐旧版 commit 列表顶部的状态头）。
    @ViewBuilder
    private var statusRow: some View {
        HStack(spacing: 6) {
            if let status {
                if status.isClean {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.success)
                    Text("Working Tree Clean")
                        .font(DesignTokens.Typography.caption2.weight(.medium))
                        .foregroundStyle(theme.textPrimary)
                    Text("All Changes Committed")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(theme.textTertiary)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.error)
                    Text("\(status.changeCount) Uncommitted Change\(status.changeCount == 1 ? "" : "s")")
                        .font(DesignTokens.Typography.caption2.weight(.medium))
                        .foregroundStyle(theme.textPrimary)
                }
                Spacer(minLength: 8)
                if let branch = status.branch {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 9))
                        Text(branch)
                            .font(DesignTokens.Typography.caption2.weight(.medium))
                    }
                    .foregroundStyle(theme.textTertiary)
                    .lineLimit(1)
                }
            } else if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background {
            Color(nsColor: .controlBackgroundColor)
        }
    }

    // MARK: - Loading

    /// 项目变化时重新加载工作区状态；`force` 为 true（提交/推送后）时强制刷新。
    private func reloadIfNeeded(force: Bool = false) {
        guard let project = projects.currentProject else {
            loadedProjectURL = nil
            status = nil
            isLoading = false
            return
        }
        if loadedProjectURL == project.url && !force { return }

        loadedProjectURL = project.url
        status = nil
        isLoading = true

        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result { try GitStatusLoader.loadStatus(in: url) }
            await MainActor.run {
                isLoading = false
                if case .success(let loaded) = result {
                    status = loaded
                }
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
