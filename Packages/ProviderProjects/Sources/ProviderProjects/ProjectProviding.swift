import Foundation
import KitGit

// MARK: - Events

/// 项目管理事件。
@MainActor
public enum ProjectProvidingEvent {
    /// 项目列表发生变化（添加 / 移除 / 置顶 / 排序 / 从磁盘重载）。
    case projectsChanged
    /// 当前项目发生变化；回调执行时 `currentProject` 已是新值。
    case selectionChanged(projectID: UUID?)
    /// 当前项目的仓库数据可能已变化（如提交 / 推送 / 分支切换后）。
    ///
    /// 消费方（commit 列表 / 工作区状态 / diff）应重新加载展示，
    /// 但**不改变**当前项目选择。
    case dataChanged
    /// 当前选中的 commit 发生变化；回调执行时 `currentCommit` / `currentCommitFiles`
    /// / `isLoadingCommitFiles` 已是新值（选中 commit 后会异步加载其变动文件）。
    case commitSelectionChanged
    /// 当前选中的文件发生变化；回调执行时 `currentFile` 已是新值。
    case currentFileChanged
}

// MARK: - Observer Handle

@MainActor
public protocol ProjectProvidingObserverHandle: AnyObject {
    func cancel()
}

// MARK: - Contract

/// 项目管理提供能力协议
///
/// 定义「内核 → 项目列表」这一段的最小契约：宿主与插件通过内核解析
/// `ProjectProviding`，读写 GitOK 的项目列表（侧边栏项目列表的数据源）。
///
/// 协议只声明逻辑能力，不关心 UI：
/// - `projects`：全部已保存项目（含置顶、最近打开排序）；
/// - `currentProject`：当前打开的项目；
/// - 打开 / 添加 / 移除 / 置顶 / 排序 / 切换当前项目。
///
/// 同时作为「当前 commit / 当前文件 / 当前 commit 下的变动的文件」这些
/// 会话级选择状态的唯一权威来源（由 commit 列表写入，commit 详情 / diff /
/// 状态栏等消费方读取）。commit 选择总是属于当前项目：切换项目时实现负责
/// 自动清空选择，保证不残留旧项目的选中状态。
///
/// 状态变化通过**观察者体系**通知（参考 Lumi 其他 Provider，如
/// `ThemeProviding`）：消费方调用 `addObserver` 订阅 `ProjectProvidingEvent`，
/// 在状态更新完成后收到回调；返回的 handle 用于取消订阅。
///
/// 持久化由实现负责（Lumi 约定：数据落在 `StorageProviding.pluginDataDirectory(for:)`
/// 指向的插件数据目录内）。
@MainActor
public protocol ProjectProviding: AnyObject {
    /// 全部已保存项目（已按置顶 + 最近打开排序）。
    var projects: [Project] { get }

    /// 当前打开的项目；未打开时为 nil。
    var currentProject: Project? { get }

    // MARK: - Commit 选择状态（唯一权威来源）

    /// 当前选中的 commit；未选中时为 nil。
    ///
    /// 选择总是属于 `currentProject`（切换项目时由实现自动清空）。
    var currentCommit: GitCommit? { get }

    /// 当前选中的 commit 内选中的文件路径；未选中文件时为 nil。
    ///
    /// 与 `currentCommit` 联动：切换 commit 时自动清空（新 commit 无选中文件）。
    /// 工作区模式（未选中 commit）下也可用于选中工作区变动文件。
    var currentFile: String? { get }

    /// 当前 commit 下的变动的文件；`nil` 表示未选中 commit 或变动文件尚未加载完成。
    ///
    /// 选中 commit 后由实现异步加载（`GitDiffLoader.loadChanges`），
    /// 加载期间为 `nil`、`isLoadingCommitFiles` 为 true，完成后更新并广播
    /// `commitSelectionChanged`。diff 视图等消费方据此渲染文件列表。
    var currentCommitFiles: [GitFileChange]? { get }

    /// 当前 commit 的变动文件是否正在加载。
    var isLoadingCommitFiles: Bool { get }

    /// 当前 commit 变动文件加载失败的错误描述（成功 / 未加载时为 nil）。
    var currentCommitFilesLoadError: String? { get }

    // MARK: - 监听

    /// 监听项目列表或当前项目变化。回调在状态更新完成后执行。
    @discardableResult
    func addObserver(_ callback: @escaping (ProjectProvidingEvent) -> Void) -> any ProjectProvidingObserverHandle

    // MARK: - 项目管理

    /// 打开一个项目（本地目录）。
    ///
    /// 若项目已存在则更新其最近打开时间并置顶排序，否则追加并保存。
    /// 同时更新 `currentProject`。
    func openProject(at url: URL)

    /// 关闭当前项目（`currentProject` 置 nil）。
    func closeCurrentProject()

    /// 追加一个项目（不改变当前项目）。重复路径忽略。
    func addProject(at url: URL)

    /// 按 id 移除项目；若移除的是当前项目则同时清空当前项目。
    func removeProject(id: UUID)

    /// 置顶 / 取消置顶指定项目。
    func pinProject(id: UUID, isPinned: Bool)

    /// 手动设置当前项目。
    func setCurrentProject(id: UUID?)

    /// 从磁盘重新加载项目列表。
    func refresh()

    /// 通知消费方当前项目的仓库数据已变化（提交 / 推送等），
    /// 不改变项目列表与当前项目选择。
    func notifyDataChanged()

    /// 持久化到磁盘。
    func persist()

    // MARK: - Commit 选择

    /// 选中一个 commit（写入 `currentCommit` 并广播 `commitSelectionChanged`）。
    ///
    /// 会同时清空 `currentFile`（新 commit 尚无选中的文件），并异步加载该
    /// commit 的变动文件到 `currentCommitFiles`。commit 必须属于当前项目。
    func selectCommit(_ commit: GitCommit)

    /// 选中当前 commit 内的某个文件（写入 `currentFile` 并广播 `currentFileChanged`）。
    /// 传 `nil` 表示取消文件选择。
    func selectFile(_ path: String?)

    /// 清除 commit 选择（`currentCommit` / `currentFile` / `currentCommitFiles` 置空）。
    ///
    /// 通常由实现内部在切换项目时调用；消费方也可显式调用（例如用户点击
    /// 工作区状态条回到工作区视图）。
    func clearCommitSelection()
}
