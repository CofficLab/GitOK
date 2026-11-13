import Combine
import Foundation
import ProviderSidebar
import ProviderToast
import SwiftUI

/// `SidebarProviding` 的项目列表实现。
///
/// 视图从 `ProjectProviding` 读取项目列表（只依赖契约，不依赖具体实现），
/// 渲染为左侧项目列表侧边栏。这是 Lumi 架构的典型用法：
/// Provider 声明能力，Plugin 跨 Provider 组装。
@MainActor
final class ProjectSidebarProviding: SidebarProviding, ObservableObject {
    @Published private(set) var items: [SidebarItem] = []

    /// 项目数据源（已收窄的插件能力）。
    private let projects: any ProjectSidebarCapability

    /// 克隆所需的 remote 解析、克隆登记与反馈能力。缺任一项时隐藏克隆入口。
    private let remoteCapability: (any GitRemoteCapability)?
    private let toast: (any ToastProviding)?
    private let clone: ProjectCloneCapability?

    /// 排序方式状态；由 Provider 持有，侧边栏视图重建不会丢失用户选择。
    let sortModeModel: ProjectSortModeModel

    /// 提交时间缓存；由 Provider 持有，重建视图不会清空缓存、重新读取。
    let activityModel: ProjectActivityModel

    /// 卷状态缓存；由 Provider 持有，重建视图不会让卷徽标重新闪一遍。
    let volumeModel: ProjectVolumeModel

    /// 项目列表派生状态缓存；由 Provider 持有，重建视图不会丢失已算好的
    /// 过滤 / 排序结果，也不会因为每次 body 求值都重排全量项目。
    let listModel: ProjectListModel

    init(
        projects: any ProjectSidebarCapability,
        remoteCapability: (any GitRemoteCapability)? = nil,
        toast: (any ToastProviding)? = nil,
        clone: ProjectCloneCapability? = nil,
        activityCapability: (any ProjectActivityCapability)? = nil,
        sortModeStore: (any ProjectSortModeStoring)? = nil,
        volumeResolver: any ProjectVolumeResolving = FileSystemProjectVolumeResolver()
    ) {
        self.projects = projects
        self.remoteCapability = remoteCapability
        self.toast = toast
        self.clone = clone
        // 未注入存储时退化为纯内存模式（预览 / 测试场景）：偏好可读可写，但不落盘。
        self.sortModeModel = ProjectSortModeModel(
            store: sortModeStore ?? InMemoryProjectSortModeStore()
        )
        self.activityModel = ProjectActivityModel(capability: activityCapability)
        self.volumeModel = ProjectVolumeModel(resolver: volumeResolver)
        self.listModel = ProjectListModel()
    }

    func registerItems(_ items: [SidebarItem]) {
        // 项目列表侧边栏不使用 SidebarItem 注入机制。
        self.items = items
    }

    func activateItem(id: String?) {}

    func makeSidebarView() -> AnyView {
        AnyView(
            ProjectSidebarView(
                projects: projects,
                toast: toast,
                clone: clone,
                remoteCapability: remoteCapability,
                sortModeModel: sortModeModel,
                activity: activityModel,
                volume: volumeModel,
                list: listModel
            )
        )
    }
}
