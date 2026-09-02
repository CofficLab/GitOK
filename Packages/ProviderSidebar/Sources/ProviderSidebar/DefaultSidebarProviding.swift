import LumiUI
import SwiftUI

/// `SidebarProviding` 的默认实现：持有注入的 `SidebarItem`，
/// 渲染为左侧列表式侧边栏（宽度与样式复用 LumiUI 的设置侧边栏组件）。
///
/// 当前为通用列表容器；后续迁移旧版 GitOK 的「项目列表」时，
/// 由注入的 `SidebarItem` 承载各项目入口即可。
@MainActor
public final class DefaultSidebarProviding: SidebarProviding, ObservableObject {
    @Published public private(set) var items: [SidebarItem] = []
    @Published public private(set) var activeItemID: String?

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
    }

    public func activateItem(id: String?) {
        guard id == nil || items.contains(where: { $0.id == id }) else { return }
        setActiveItemID(id)
    }

    public func makeSidebarView() -> AnyView {
        AnyView(SidebarView(provider: self))
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
}

/// 渲染侧边栏项的列表视图。
private struct SidebarView: View {
    @ObservedObject var provider: DefaultSidebarProviding

    var body: some View {
        AppSettingsSidebarContainer(width: 220) {
            VStack(spacing: 0) {
                if provider.items.isEmpty {
                    EmptySidebarPlaceholder()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 2) {
                            ForEach(provider.items) { item in
                                AppSettingsSidebarItem(
                                    title: item.title,
                                    systemImage: item.systemImage,
                                    isSelected: provider.activeItemID == item.id
                                ) {
                                    provider.activateItem(id: item.id)
                                }
                                .id(item.id)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
    }
}

/// 侧边栏暂无条目时的占位视图。
private struct EmptySidebarPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
            Text("No Items")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
