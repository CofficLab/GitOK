import Foundation
import KitGit

/// Git Diff 插件的自有状态模型。
///
/// 由插件入口在装配阶段创建并注入视图；`GitDiffObserver` 把外部（Provider）
/// 事件翻译成本模型的领域方法。视图只绑定本模型，不再直接读取 Provider
/// 或注册外部监听。
///
/// diff 以「当前文件」为驱动，commit 只作为可选上下文：
/// 选中文件后即可渲染——有 commit 时展示该文件在该 commit 中的 diff，
/// 无 commit（工作区变动）时展示该文件相对工作区的 diff。
@MainActor
final class GitDiffViewModel: ObservableObject {
    /// 当前选中的 commit（可选上下文）；未选中时为 nil（工作区模式）。
    @Published private(set) var selectedCommit: GitCommit?

    /// 选中 commit / 文件所属的项目路径。
    @Published private(set) var selectedProjectURL: URL?

    /// 当前选中的文件路径（diff 的唯一驱动）；未选中文件时为 nil。
    @Published private(set) var selectedFile: String?

    /// 项目选择状态变化版本号（commit / 文件 / 仓库数据变化后递增）。
    ///
    /// 视图据此触发 diff 重载（`loadIfNeeded` 内部按「commit 上下文 + 文件」
    /// 组合去重，只有组合真正变化时才重新加载）。
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
