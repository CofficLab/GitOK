import Foundation
import KitGit

/// 提交详情插件的自有状态模型。
///
/// 由插件入口在装配阶段创建并注入视图；`CommitDetailObserver` 把外部
/// （Provider）事件翻译成本模型的领域方法。视图只绑定本模型，不再直接
/// 读取 Provider 或监听系统通知。
@MainActor
final class CommitDetailViewModel: ObservableObject {
    /// 当前选中的 commit；未选中时为 nil。
    @Published private(set) var selectedCommit: GitCommit?

    /// 当前项目路径（有选中 commit 时即为该 commit 所属项目路径）。
    @Published private(set) var selectedProjectURL: URL?

    /// 当前选中的 commit 内选中的文件路径；未选中文件时为 nil。
    @Published private(set) var selectedFile: String?

    /// 当前 commit 下的变动的文件；`nil` 表示未选中 commit 或加载中。
    @Published private(set) var currentCommitFiles: [GitFileChange]?

    /// 当前 commit 的变动文件是否正在加载。
    @Published private(set) var isLoadingCommitFiles = false

    /// 当前 commit 变动文件加载失败的错误描述。
    @Published private(set) var commitFilesLoadError: String?

    /// 仓库数据变化版本号（提交 / 推送 / 分支切换后递增）。
    ///
    /// 工作区变动列表据此强制重载；commit 详情内容不可变，无需重载。
    @Published private(set) var worktreeRevision = 0

    /// 外部项目 / 选中状态变化 → 同步最新值。
    func handleSelectionChanged(commit: GitCommit?, projectURL: URL?, file: String?) {
        selectedCommit = commit
        selectedProjectURL = projectURL
        selectedFile = file
    }

    /// 外部 commit 变动文件状态变化 → 同步最新值。
    func handleCommitFilesChanged(files: [GitFileChange]?, isLoading: Bool, loadError: String?) {
        currentCommitFiles = files
        isLoadingCommitFiles = isLoading
        commitFilesLoadError = loadError
    }

    /// 外部仓库数据变化（提交 / 推送 / 分支切换）→ 通知工作区视图重载。
    func handleProjectDataChanged() {
        worktreeRevision &+= 1
    }
}
