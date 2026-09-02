import Combine
import Foundation

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
/// 持久化由实现负责（Lumi 约定：数据落在 `StorageProviding.pluginDataDirectory(for:)`
/// 指向的插件数据目录内）。
@MainActor
public protocol ProjectProviding: AnyObject, ObservableObject
    where ObjectWillChangePublisher == ObservableObjectPublisher {
    /// 全部已保存项目（已按置顶 + 最近打开排序）。
    var projects: [Project] { get }

    /// 当前打开的项目；未打开时为 nil。
    var currentProject: Project? { get }

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

    /// 持久化到磁盘。
    func persist()
}
