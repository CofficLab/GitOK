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

    /// 已检查过工作区状态的项目 URL（用于避免对同一项目重复加载）。
    private var checkedProjectURL: URL?

    /// 外部项目 / 选中状态变化（打开 / 切换 / 关闭项目、选中 / 取消 commit）。
    ///
    /// 干净视图只在「有项目 + 未选中 commit」时展示，其余情况直接隐藏。
    func handleProjectChanged(project: Project?, hasSelectedCommit: Bool) {
        self.project = project
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
    private func reload(force: Bool = false) {
        guard let project else {
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
                // 仅当仍指向同一项目时应用结果，避免切换项目后残留旧状态。
                guard self.project?.url == url else { return }
                self.isClean = clean
                self.isLoading = false
            }
        }
    }
}
