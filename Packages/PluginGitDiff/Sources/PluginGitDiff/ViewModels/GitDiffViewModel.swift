import Foundation
import KitGit

/// Git Diff 插件的自有状态模型。
///
/// 由插件入口在装配阶段创建并注入视图；`GitDiffObserver` 把外部（Provider）
/// 事件翻译成本模型的领域方法。视图只绑定本模型，不再直接读取 Provider
/// 或注册外部监听。
@MainActor
final class GitDiffViewModel: ObservableObject {
    /// 当前选中的 commit；未选中时为 nil。
    @Published private(set) var selectedCommit: GitCommit?

    /// 选中 commit 所属的项目路径。
    @Published private(set) var selectedProjectURL: URL?

    /// 当前选中的 commit 内选中的文件路径；未选中文件时为 nil。
    @Published private(set) var selectedFile: String?

    /// 项目选择状态变化版本号（commit / 文件 / 仓库数据变化后递增）。
    ///
    /// 视图据此触发 diff 重载（`loadIfNeeded` 内部按 commit + 文件组合去重，
    /// 只有组合真正变化时才重新加载）。
    @Published private(set) var revision = 0

    /// 外部选中状态变化（commit 或文件）→ 同步最新值并递增版本号。
    func handleSelectionChanged(commit: GitCommit?, projectURL: URL?, file: String?) {
        selectedCommit = commit
        selectedProjectURL = projectURL
        selectedFile = file
        revision &+= 1
    }

    /// 外部仓库数据变化（提交 / 推送 / 分支切换）→ 递增版本号触发视图重载。
    func handleProjectDataChanged() {
        revision &+= 1
    }
}
