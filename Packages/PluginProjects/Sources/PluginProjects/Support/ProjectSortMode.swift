import Foundation
import ProviderProjects

/// 项目列表的展示方式（排序规则）。
///
/// 项目数量少时默认沿用保存下来的手动顺序；项目变多后，用户在侧边栏底部
/// 的排序栏里切换本枚举，用不同的规则重新排列列表，便于在大量项目中
/// 快速定位目标。
///
/// 三种规则都遵循同一条约定：**置顶项目始终排在最前**，置顶组与普通组
/// 各自独立排序——这样「Pin to Top」在切换展示方式后依然成立。
enum ProjectSortMode: String, CaseIterable, Identifiable, Sendable {
    /// 手动排序：沿用项目列表中保存的顺序（置顶在前，其余按用户调整的顺序）。
    case manual
    /// 最近更新：按仓库最近一次提交时间倒序；没有提交时间的项目排在最后。
    /// 排序只依赖仓库提交时间，点击项目（更新最近打开时间）不会改变顺序。
    case recent
    /// 按名称：按项目名称升序。
    case name

    var id: String { rawValue }

    /// 标签栏上的短标题（本地化 key）。
    var titleKey: String {
        switch self {
        case .manual: "Manual"
        case .recent: "Recent Update"
        case .name: "Name"
        }
    }

    /// 标签栏图标。
    var systemImage: String {
        switch self {
        case .manual: "square.grid.2x2"
        case .recent: "clock.arrow.circlepath"
        case .name: "textformat.abc"
        }
    }

    /// 该规则是否依赖仓库提交时间（需要 Git 能力才能得到完整结果）。
    var requiresCommitActivity: Bool {
        self == .recent
    }

    /// 按当前规则重排项目列表。
    ///
    /// - Parameters:
    ///   - projects: 原始项目列表（通常已按置顶 + 手动顺序排列）。
    ///   - commitDates: 各项目的最近提交时间；缺失时该项目排在最后。
    /// - Returns: 重排后的列表，置顶项目仍在最前。
    func sorted(_ projects: [Project], commitDates: [UUID: Date] = [:]) -> [Project] {
        switch self {
        case .manual:
            return projects
        case .name:
            return Self.sortedByGroups(projects) { lhs, rhs in
                let order = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
                if order != .orderedSame { return order }
                return lhs.url.path.compare(rhs.url.path)
            }
        case .recent:
            return Self.sortedByGroups(projects) { lhs, rhs in
                let left = commitDates[lhs.id]
                let right = commitDates[rhs.id]
                switch (left, right) {
                case let (left?, right?):
                    if left != right { return left > right ? .orderedAscending : .orderedDescending }
                    let order = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
                    if order != .orderedSame { return order }
                    return lhs.url.path.compare(rhs.url.path)
                case (_?, nil):
                    return .orderedAscending
                case (nil, _?):
                    return .orderedDescending
                case (nil, nil):
                    // 两边的提交时间都未知（缓存冷）：保持原始顺序。
                    // 用标题兜底会把列表退化成字母序，缓存就绪后又跳回来。
                    return .orderedSame
                }
            }
        }
    }

    // MARK: - Helpers

    /// 置顶组与普通组分别排序后拼接，保持置顶项目始终在最前。
    ///
    /// 单趟遍历完成分组，避免两次 `filter` 各产生一份中间数组。
    private static func sortedByGroups(
        _ projects: [Project],
        by areInIncreasingOrder: (Project, Project) -> ComparisonResult
    ) -> [Project] {
        var pinned: [Project] = []
        var unpinned: [Project] = []
        pinned.reserveCapacity(projects.count)
        unpinned.reserveCapacity(projects.count)
        for project in projects {
            if project.isPinned {
                pinned.append(project)
            } else {
                unpinned.append(project)
            }
        }
        return stableSorted(pinned, by: areInIncreasingOrder)
            + stableSorted(unpinned, by: areInIncreasingOrder)
    }

    /// 稳定排序：比较结果相同时保持原始相对顺序。
    ///
    /// 比较闭包只求值一次。旧实现对每一对元素最多调用两次比较闭包
    /// （`areInIncreasingOrder(lhs, rhs)` 与 `areInIncreasingOrder(rhs, lhs)`），
    /// 把 `localizedCaseInsensitiveCompare` 这类带 locale 归一化的比较开销
    /// 直接翻倍；项目上千时这一项就是排序耗时的主因。
    static func stableSorted(
        _ projects: [Project],
        by areInIncreasingOrder: (Project, Project) -> ComparisonResult
    ) -> [Project] {
        guard projects.count > 1 else { return projects }
        return projects.enumerated()
            .sorted { lhs, rhs in
                let order = areInIncreasingOrder(lhs.element, rhs.element)
                if order != .orderedSame { return order == .orderedAscending }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
