import KitGit
import ProviderGit

/// 工作区变更列表的内容状态。
///
/// 视图不再用「条目是否为空」直接推断该渲染什么：读到空结果既可能是工作区真的
/// 干净，也可能是扫描尚未完成或结果被作废。两者必须区分，否则主内容区会在扫描
/// 期间塌陷（提交表单漂到面板中间、详情区留白）。
enum WorktreeChangesContent: Equatable {
    /// 尚未拿到可信快照：展示加载占位，占满可用高度。
    case loading
    /// 扫描失败：展示错误提示。
    case failed(String)
    /// 工作区确认干净：变更列表不占布局，由干净概览展示仓库信息。
    case clean
    /// 工作区存在未提交变更：展示文件列表。
    case changes([GitStatusEntry])
}

/// 把「共享归属 + 本地条目 + 错误」映射成内容状态的纯规则。
///
/// 归属方（`WorktreeContentOwner`）由 Provider 统一广播，变更列表与干净概览
/// 使用同一份判定，因此任何时刻两块内容不会同时「不占布局」。
enum WorktreeChangesContentPolicy {
    static func resolve(
        owner: WorktreeContentOwner,
        entries: [GitStatusEntry],
        loadError: String?
    ) -> WorktreeChangesContent {
        if let loadError, !loadError.isEmpty {
            return .failed(loadError)
        }
        switch owner {
        case .pending:
            // 归属还没结论，但本地已有上一份快照（项目切换时的缓存）：
            // 立即展示缓存内容，后台刷新，不退回加载占位。
            return entries.isEmpty ? .loading : .changes(entries)
        case .clean:
            return .clean
        case .changes:
            // 归属已是「有变更」但本地条目还没落地：继续展示加载占位，
            // 不用空列表把整块内容塌陷掉。
            return entries.isEmpty ? .loading : .changes(entries)
        }
    }
}
