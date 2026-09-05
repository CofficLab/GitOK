import SwiftUI
import ProviderWorkspaceScene

/// `SidebarProviding` 的默认实现：持有注入的 `SidebarItem`，
/// 渲染为左侧列表式侧边栏（宽度与样式复用 LumiUI 的设置侧边栏组件）。
///
/// 当前为通用列表容器；后续迁移旧版 GitOK 的「项目列表」时，
/// 由注入的 `SidebarItem` 承载各项目入口即可。
@MainActor
public final class DefaultSidebarProvider: SidebarProviding, ObservableObject {
    @Published public private(set) var items: [SidebarItem] = []
    @Published public private(set) var activeItemID: String?

    private var sceneObserver: (any WorkspaceSceneObserverHandle)?
    private var workspaceSceneProvider: (any WorkspaceSceneProviding)?

    public init() {}

    public func registerItems(_ items: [SidebarItem]) {
        let previousItems = self.items
        self.items = items.sorted { $0.order < $1.order }
        let nextActiveID: String?
        if let activeItemID, self.items.contains(where: { $0.id == activeItemID }) {
            nextActiveID = activeItemID
        } else {
            nextActiveID = self.items.first?.id
        }
        setActiveItemID(nextActiveID, previousItems: previousItems)
        reconcileVisibleItem()
    }

    public func activateItem(id: String?) {
        guard id == nil || visibleItems.contains(where: { $0.id == id }) else { return }
        setActiveItemID(id)
    }

    public func makeSidebarView() -> AnyView {
        AnyView(SidebarView(provider: self))
    }

    public func bindWorkspaceSceneProvider(_ provider: any WorkspaceSceneProviding) {
        sceneObserver?.cancel()
        workspaceSceneProvider = provider
        sceneObserver = provider.addObserver { [weak self] _ in
            self?.reconcileVisibleItem()
        }
        reconcileVisibleItem()
    }

    var visibleItems: [SidebarItem] {
        guard let scene = workspaceSceneProvider?.currentScene else { return items }
        return items.filter { $0.sceneScope.matches(scene) }
    }

    private func setActiveItemID(_ id: String?, previousItems: [SidebarItem]? = nil) {
        guard activeItemID != id else { return }
        let previousID = activeItemID
        activeItemID = id

        if let previousID,
           let previousItem = (previousItems ?? items).first(where: { $0.id == previousID }) {
            previousItem.onActivationChanged(.deactivated)
        }

        if let id,
           let nextItem = items.first(where: { $0.id == id }), id != previousID {
            nextItem.onActivationChanged(.activated)
        }
    }

    private func reconcileVisibleItem() {
        let visible = visibleItems
        guard let activeItemID,
              visible.contains(where: { $0.id == activeItemID }) else {
            setActiveItemID(visible.first?.id)
            return
        }
    }
}
