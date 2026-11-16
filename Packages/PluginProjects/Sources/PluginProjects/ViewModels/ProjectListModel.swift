import Combine
import Foundation
import ProviderProjects

/// 项目列表的派生状态模型：把「项目列表 + 排序规则 + 提交时间 + 搜索词」
/// 这四个输入收敛成**一份缓存**的过滤排序结果。
///
/// 解决的问题（GitOK issue #18）：
/// 侧边栏此前把过滤 / 排序写成视图的 computed property，于是
/// - 每次 body 求值都会对全量项目重新过滤 + 重新排序；
/// - 分隔线索引在 `ForEach` 里被反复访问，等于**每个可见行**都重排一次；
/// - 搜索框每敲一个字符就触发一次全量过滤。
///
/// 本模型把这些计算收敛到一处：
/// - 输入未变化时直接复用上一次的果（`update` 里做等值比较）；
/// - 置顶 / 普通分界位置一次算出，视图只读取；
/// - 搜索词带防抖，连续输入只过滤一次。
///
/// 模型由 Provider 持有（与 `ProjectActivityModel` / `ProjectVolumeModel` 一致），
/// 根布局重建侧边栏视图时缓存不会丢失。
@MainActor
final class ProjectListModel: ObservableObject {
    /// 搜索防抖间隔：连续输入时只在停顿后过滤一次。
    static let searchDebounceInterval: Duration = .milliseconds(150)

    /// 过滤 + 排序后的项目列表（侧边栏直接消费）。
    @Published private(set) var filteredProjects: [Project] = []

    /// 置顶区与普通区的分界索引；`nil` 表示无需分隔线。
    @Published private(set) var pinnedDividerIndex: Int?

    /// 分隔线应绘制在该索引**之后**的行上（用项目 id 表达，避免视图额外物化
    /// `enumerated()` 数组）。
    @Published private(set) var pinnedDividerAfterID: UUID?

    /// 全部项目中的置顶数量。
    @Published private(set) var pinnedProjectCount: Int = 0

    /// 全部项目数量。
    @Published private(set) var totalCount: Int = 0

    /// 是否存在任何项目（用于区分「没有项目」与「没有匹配结果」）。
    @Published private(set) var hasProjects: Bool = false

    // MARK: - Inputs

    private var allProjects: [Project] = []
    private var sortMode: ProjectSortMode = .manual
    private var commitDates: [UUID: Date] = [:]

    /// 已生效的搜索词。
    private var appliedSearchText: String = ""
    /// 待生效的搜索词（防抖窗口内）。
    private var pendingSearchText: String = ""

    private var debounceTask: Task<Void, Never>?

    deinit {
        debounceTask?.cancel()
    }

    // MARK: - Inputs

    /// 更新列表输入；输入未真正变化时不重算列表。
    ///
    /// - Parameters:
    ///   - projects: 全部项目（原始顺序）。
    ///   - sortMode: 当前排序规则。
    ///   - commitDates: 各项目最近提交时间（「最近更新」排序用）。
    func update(projects: [Project], sortMode: ProjectSortMode, commitDates: [UUID: Date]) {
        var changed = false
        if allProjects != projects {
            allProjects = projects
            changed = true
        }
        if self.sortMode != sortMode {
            self.sortMode = sortMode
            changed = true
        }
        if self.commitDates != commitDates {
            self.commitDates = commitDates
            changed = true
        }
        if changed {
            recompute()
        }
    }

    /// 设置搜索词；防抖后生效，避免每个字符都触发全量过滤。
    func setSearchText(_ text: String) {
        guard text != pendingSearchText else { return }
        pendingSearchText = text
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: Self.searchDebounceInterval)
            guard !Task.isCancelled else { return }
            self?.applySearchText(text)
        }
    }

    /// 立即应用搜索词（跳过防抖）；供测试与「清空搜索」等即时场景使用。
    func applySearchTextImmediately(_ text: String) {
        pendingSearchText = text
        debounceTask?.cancel()
        debounceTask = nil
        applySearchText(text)
    }

    private func applySearchText(_ text: String) {
        guard text != appliedSearchText else { return }
        appliedSearchText = text
        recompute()
    }

    // MARK: - Recompute

    /// 重算过滤 + 排序结果，并一次性更新派生状态。
    private func recompute() {
        let needle = appliedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matched: [Project]
        if needle.isEmpty {
            matched = allProjects
        } else {
            matched = allProjects.filter { $0.title.localizedCaseInsensitiveContains(needle) }
        }

        let sorted = sortMode.sorted(matched, commitDates: commitDates)

        filteredProjects = sorted
        totalCount = allProjects.count
        hasProjects = !allProjects.isEmpty
        pinnedProjectCount = allProjects.reduce(into: 0) { count, project in
            if project.isPinned { count += 1 }
        }

        let divider = Self.dividerIndex(in: sorted)
        pinnedDividerIndex = divider
        if let divider, divider > 0 {
            pinnedDividerAfterID = sorted[divider - 1].id
        } else {
            pinnedDividerAfterID = nil
        }
    }

    /// 置顶区与普通区的分界位置。
    ///
    /// 只有置顶组与普通组都存在时才需要分隔线；分隔线画在最后一个置顶项目之后。
    static func dividerIndex(in sortedProjects: [Project]) -> Int? {
        guard let firstUnpinned = sortedProjects.firstIndex(where: { !$0.isPinned }) else {
            return nil
        }
        guard sortedProjects.contains(where: \.isPinned) else { return nil }
        return firstUnpinned
    }
}
