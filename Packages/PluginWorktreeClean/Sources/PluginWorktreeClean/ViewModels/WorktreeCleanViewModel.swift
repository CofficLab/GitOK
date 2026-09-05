import Foundation
import KitGit
import ProviderProjects

/// 工作区干净视图的自有状态模型。
///
/// 由插件入口在装配阶段创建并注入视图；`WorktreeCleanObserver` 把外部
/// （Provider / GitRepositoryWatching）事件翻译成本模型的领域方法。
/// 视图只绑定本模型，不再直接读取 Provider 或监听系统通知。
@MainActor
final class WorktreeCleanViewModel: ObservableObject {
    /// 当前项目；未打开项目时为 nil。
    @Published private(set) var project: Project?

    /// 当前项目工作区是否干净（无未提交变更）。
    @Published private(set) var isClean = false

    /// 是否正在首次检查工作区状态。
    @Published private(set) var isLoading = false

    /// 当前是否选中了 commit。
    ///
    /// 干净视图只在「有项目 + 未选中 commit」时展示；把该状态存下来是为了让
    /// 后续 `handleDataChanged`（提交 / 推送 / 分支切换 / 外部编辑触发）触发的
    /// `reload` 也保持隐藏——否则已选 commit 后的一次 dataChanged 会因工作区
    /// 干净而重新亮起干净视图，盖住 commit 详情。
    private var hasSelectedCommit = false

    /// 已检查过工作区状态的项目 URL（用于避免对同一项目重复加载）。
    private var checkedProjectURL: URL?

    /// 最近一次成功读取的工作区快照。
    ///
    /// 文件监听会报告所有工作区文件变化，其中一部分不会改变 Git 状态
    /// （例如被忽略的文件，或文件很快恢复原状）。保留快照后，这类事件只
    /// 触发后台检查，不会重复更新 SwiftUI 状态。
    private var lastStatus: GitWorktreeStatus?

    /// 加载序号：只接受最后一次检查结果，避免旧任务覆盖新快照。
    private var loadToken = 0

    /// 外部项目 / 选中状态变化（打开 / 切换 / 关闭项目、选中 / 取消 commit）。
    ///
    /// 干净视图只在「有项目 + 未选中 commit」时展示，其余情况直接隐藏。
    func handleProjectChanged(project: Project?, hasSelectedCommit: Bool) {
        let previousProjectURL = self.project?.url
        let previousHasSelectedCommit = self.hasSelectedCommit
        if self.project != project {
            self.project = project
        }
        self.hasSelectedCommit = hasSelectedCommit
        let projectChanged = previousProjectURL != project?.url
        if projectChanged {
            checkedProjectURL = nil
            lastStatus = nil
            if isClean {
                isClean = false
            }
        }
        guard project != nil, !hasSelectedCommit else {
            loadToken &+= 1
            if isClean {
                isClean = false
            }
            if isLoading {
                isLoading = false
            }
            checkedProjectURL = nil
            lastStatus = nil
            return
        }
        let selectionChanged = previousHasSelectedCommit != hasSelectedCommit
        reload(force: projectChanged || selectionChanged)
    }

    /// 外部仓库 / 工作区数据变化（提交 / 推送 / 分支切换 / 外部编辑文件）。
    ///
    /// 提交、外部把工作区改干净后，干净状态需要据此重新判定。
    func handleDataChanged() {
        reload(force: true)
    }

    // MARK: - Private

    /// 重新检查当前项目工作区是否干净。
    ///
    /// 选中 commit 后工作区数据变化不应重新点亮干净视图，因此这里同样
    /// 以 `!hasSelectedCommit` 为前提（与 `handleProjectChanged` 一致）。
    private func reload(force: Bool = false) {
        guard let project, !hasSelectedCommit else {
            loadToken &+= 1
            if isClean {
                isClean = false
            }
            if isLoading {
                isLoading = false
            }
            checkedProjectURL = nil
            lastStatus = nil
            return
        }
        if checkedProjectURL == project.url && lastStatus != nil && !force { return }

        loadToken &+= 1
        let token = loadToken
        checkedProjectURL = project.url

        // 与 commitlist 保留已有列表的策略一致：已有快照时保持当前页面稳定，
        // 不因为一次后台校验而切换加载态。首次加载仍显示 loading 状态。
        if lastStatus == nil {
            isLoading = true
        }

        let url = project.url
        Task.detached(priority: .utility) {
            let result = Result { try GitStatusLoader.loadStatus(in: url) }
            await MainActor.run {
                // 仅当仍指向同一项目、且仍未选中 commit 时应用结果，
                // 且只接受最后一次检查结果，避免切换项目或连续事件造成旧状态覆盖。
                guard token == self.loadToken,
                      self.project?.url == url,
                      !self.hasSelectedCommit else { return }

                switch result {
                case .success(let status):
                    let didChange = WorktreeCleanRefreshPolicy.didChange(
                        previous: self.lastStatus,
                        current: status
                    )
                    self.lastStatus = status
                    if didChange, self.isClean != status.isClean {
                        self.isClean = status.isClean
                    }
                    if self.isLoading {
                        self.isLoading = false
                    }
                case .failure:
                    // 检查失败时保留已有状态，避免一次瞬时 git 错误把页面
                    // 错误地切换成「干净」或「有变更」。首次检查则结束 loading。
                    if self.isLoading {
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

/// 工作区刷新时的纯数据判断，供 ViewModel 和测试复用。
enum WorktreeCleanRefreshPolicy {
    static func didChange(previous: GitWorktreeStatus?, current: GitWorktreeStatus) -> Bool {
        previous != current
    }
}
