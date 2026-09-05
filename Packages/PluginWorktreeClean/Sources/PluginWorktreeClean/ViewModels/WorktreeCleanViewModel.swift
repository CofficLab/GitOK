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

    /// 是否正在检查工作区状态。
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

    /// 外部项目 / 选中状态变化（打开 / 切换 / 关闭项目、选中 / 取消 commit）。
    ///
    /// 干净视图只在「有项目 + 未选中 commit」时展示，其余情况直接隐藏。
    func handleProjectChanged(project: Project?, hasSelectedCommit: Bool) {
        self.project = project
        self.hasSelectedCommit = hasSelectedCommit
        guard project != nil, !hasSelectedCommit else {
            isClean = false
            isLoading = false
            checkedProjectURL = nil
            return
        }
        reload(force: true)
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
            isClean = false
            isLoading = false
            checkedProjectURL = nil
            return
        }
        if checkedProjectURL == project.url && !force { return }
        checkedProjectURL = project.url
        isLoading = true

        let url = project.url
        Task.detached(priority: .utility) {
            let entries = (try? GitStatusLoader.loadEntries(in: url)) ?? []
            let clean = entries.isEmpty
            await MainActor.run {
                // 仅当仍指向同一项目、且仍未选中 commit 时应用结果，
                // 避免切换项目或选中 commit 后残留旧状态。
                guard self.project?.url == url, !self.hasSelectedCommit else { return }
                self.isClean = clean
                self.isLoading = false
            }
        }
    }
}
