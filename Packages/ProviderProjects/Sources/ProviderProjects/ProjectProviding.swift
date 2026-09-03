import Foundation

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

    /// 监听项目列表或当前项目变化。回调在状态更新完成后执行。
    @discardableResult
    func addObserver(_ callback: @escaping (ProjectProvidingEvent) -> Void) -> any ProjectProvidingObserverHandle

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
}
