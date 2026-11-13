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

    /// 读取仓库最近提交时间的能力（供「最近更新」展示方式使用）。
    private let activityCapability: (any ProjectActivityCapability)?

    /// 克隆所需的 remote 解析、克隆登记与反馈能力。缺任一项时隐藏克隆入口。
    private let remoteCapability: (any GitRemoteCapability)?
    private let toast: (any ToastProviding)?
    private let clone: ProjectCloneCapability?

    /// 排序方式状态；由 Provider 持有，侧边栏视图重建不会丢失用户选择。
    let sortModeModel: ProjectSortModeModel

    init(
        projects: any ProjectSidebarCapability,
        remoteCapability: (any GitRemoteCapability)? = nil,
        toast: (any ToastProviding)? = nil,
        clone: ProjectCloneCapability? = nil,
        activityCapability: (any ProjectActivityCapability)? = nil,
        sortModeStore: (any ProjectSortModeStoring)? = nil
    ) {
        self.projects = projects
        self.remoteCapability = remoteCapability
        self.toast = toast
        self.clone = clone
        self.activityCapability = activityCapability
        // 未注入存储时退化为纯内存模式（预览 / 测试场景）：偏好可读可写，但不落盘。
        self.sortModeModel = ProjectSortModeModel(
            store: sortModeStore ?? InMemoryProjectSortModeStore()
        )
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
                activityCapability: activityCapability,
                sortModeModel: sortModeModel
            )
        )
    }
}
