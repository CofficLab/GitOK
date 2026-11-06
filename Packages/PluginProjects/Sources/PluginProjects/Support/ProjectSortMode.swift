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
    /// 最近更新：按仓库最近一次提交时间倒序；没有提交信息时回退到最近打开时间。
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
    ///   - commitDates: 各项目的最近提交时间；缺失时回退到 `lastOpenedAt`。
    /// - Returns: 重排后的列表，置顶项目仍在最前。
    func sorted(_ projects: [Project], commitDates: [UUID: Date] = [:]) -> [Project] {
        switch self {
        case .manual:
            return projects
        case .name:
            return Self.sortedByGroups(projects) { lhs, rhs in
                let order = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
                if order != .orderedSame { return order == .orderedAscending }
                return lhs.url.path < rhs.url.path
            }
        case .recent:
            return Self.sortedByGroups(projects) { lhs, rhs in
                let left = Self.activityDate(for: lhs, commitDates: commitDates)
                let right = Self.activityDate(for: rhs, commitDates: commitDates)
                if left != right { return left > right }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }

    // MARK: - Helpers

    /// 项目用于「最近更新」排序的时间：优先提交时间，回退到最近打开时间。
    static func activityDate(for project: Project, commitDates: [UUID: Date]) -> Date {
        if let commitDate = commitDates[project.id] {
            return commitDate
        }
        return project.lastOpenedAt ?? .distantPast
    }

    /// 置顶组与普通组分别排序后拼接，保持置顶项目始终在最前。
    private static func sortedByGroups(
        _ projects: [Project],
        by areInIncreasingOrder: (Project, Project) -> Bool
    ) -> [Project] {
        let pinned = stableSorted(projects.filter(\.isPinned), by: areInIncreasingOrder)
        let unpinned = stableSorted(projects.filter { !$0.isPinned }, by: areInIncreasingOrder)
        return pinned + unpinned
    }

    /// 稳定排序：比较结果相同时保持原始相对顺序。
    private static func stableSorted(
        _ projects: [Project],
        by areInIncreasingOrder: (Project, Project) -> Bool
    ) -> [Project] {
        projects.enumerated()
            .sorted { lhs, rhs in
                if areInIncreasingOrder(lhs.element, rhs.element) { return true }
                if areInIncreasingOrder(rhs.element, lhs.element) { return false }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
