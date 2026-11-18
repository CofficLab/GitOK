import Combine

/// 项目侧边栏排序方式的状态模型。
///
/// 排序方式是展示偏好，但状态必须由 Provider 持有而不是视图持有：侧边栏
/// 视图可能随根布局重建被重新创建，视图本地 `@State` 会随之丢失，用户选中
/// 的排序方式会跳回默认值。
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
