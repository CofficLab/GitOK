import SwiftUI
import ProviderWorkspaceScene

// MARK: - Sidebar Item

/// 侧边栏入口项（由外部注入）。
///
/// 描述侧边栏上的一个入口（id / 标题 / 图标 / 排序），
/// 内容由其他 Provider（如 ContentViewProviding）负责展示。
///
/// `ownerPluginID` 用于跟踪该入口所属的插件，便于插件卸载/禁用时自动移除入口、
/// 重新启用时自动恢复入口。
@MainActor
public struct SidebarItem: Identifiable {
    public enum ActivationState: Sendable {
        case activated
        case deactivated
    }

    public let id: String
    public let title: String
    public let systemImage: String
    public var order: Int
    /// 侧边栏项可见的工作场景范围。
    public let sceneScope: WorkspaceSceneScope
    /// 该入口所属插件的 id（可选）。
    ///
    /// 为 nil 时表示该入口不受插件生命周期管理（如内置欢迎入口）。
    public let ownerPluginID: String?
    /// 该入口自身的激活状态变化时回调。
    ///
    /// 侧边栏只向状态发生变化的入口发送通知：切换入口时，先通知旧入口
    /// `deactivated`，再通知新入口 `activated`。
    public let onActivationChanged: @MainActor (ActivationState) -> Void

    public init(
        id: String,
        title: String,
        systemImage: String,
        order: Int = 200,
        sceneScope: WorkspaceSceneScope = .global,
        ownerPluginID: String? = nil,
        onActivationChanged: @escaping @MainActor (ActivationState) -> Void = { _ in }
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.order = order
        self.sceneScope = sceneScope
        self.ownerPluginID = ownerPluginID
        self.onActivationChanged = onActivationChanged
    }
}
