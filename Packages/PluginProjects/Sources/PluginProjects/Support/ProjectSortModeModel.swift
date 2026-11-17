import Combine

/// 项目侧边栏排序方式的状态模型。
///
/// 排序方式是展示偏好，但状态必须由 Provider 持有而不是视图持有：根布局在
/// 工作区状态变化（切换项目、卷不可用等）时会重建侧边栏视图，视图本地
/// `@State` 会随重建丢失，用户选中的排序方式会跳回默认值。
///
/// 本模型在 Provider 生命周期内只创建一次，读写都经由
/// `ProjectSortModeStoring` 落盘（插件数据目录下的 `settings.plist`）。
@MainActor
final class ProjectSortModeModel: ObservableObject {
    /// 当前排序方式；只能通过 `setMode(_:)` 修改，保证与磁盘一致。
    @Published private(set) var mode: ProjectSortMode

    private let store: any ProjectSortModeStoring

    init(store: any ProjectSortModeStoring) {
        self.store = store
        mode = store.loadSortMode() ?? .manual
    }

    func setMode(_ newMode: ProjectSortMode) {
        guard newMode != mode else { return }
        mode = newMode
        store.saveSortMode(newMode)
    }
}
