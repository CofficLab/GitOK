import Foundation

/// 项目排序偏好的持久化接口。
@MainActor
protocol ProjectSortModeStoring: AnyObject {
    func loadSortMode() -> ProjectSortMode?
    func saveSortMode(_ mode: ProjectSortMode)
}

/// 使用 `UserDefaults` 保存项目侧边栏的展示方式。
///
/// 排序偏好属于「界面偏好」而非项目数据，因此不写进 `projects.json`——
/// 换机器同步项目列表时不会把排序偏好一起带走，这是符合预期的行为。
@MainActor
final class UserDefaultsProjectSortModeStore: ProjectSortModeStoring {
    private let defaults: UserDefaults
    private let key: String

    init(
        defaults: UserDefaults = .standard,
        key: String = "com.coffic.gitok.project-sort-mode"
    ) {
        self.defaults = defaults
        self.key = key
    }

    func loadSortMode() -> ProjectSortMode? {
        guard let raw = defaults.string(forKey: key) else { return nil }
        return ProjectSortMode(rawValue: raw)
    }

    func saveSortMode(_ mode: ProjectSortMode) {
        defaults.set(mode.rawValue, forKey: key)
    }
}
