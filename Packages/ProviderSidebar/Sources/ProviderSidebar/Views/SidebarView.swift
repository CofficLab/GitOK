import LumiUI
import SwiftUI

/// 渲染侧边栏项的列表视图。
///
/// 持有 `DefaultSidebarProvider` 并观察其 `items` / `activeItemID`，
/// 把注入的 `SidebarItem` 渲染为 LumiUI 设置侧边栏风格的列表。
struct SidebarView: View {
    @ObservedObject var provider: DefaultSidebarProvider

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
