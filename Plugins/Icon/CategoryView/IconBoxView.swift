import MagicCore
import SwiftUI

/**
 * 图标盒子视图
 * 负责管理分类选择和图标展示的整体布局
 * 数据流：IconCategoryRepo -> IconCategory -> IconAsset List
 */
struct IconBoxView: View {
    @EnvironmentObject var iconProvider: IconProvider
    @State private var gridItems: [GridItem] = Array(repeating: .init(.flexible()), count: 10)
    
    var body: some View {
        VStack(spacing: 0) {
            // 分类标签页
            CategoryTabs()
            
            // 图标网格
            GeometryReader { geo in
                ScrollView {
                    VStack {
                        if let selectedCategory = iconProvider.selectedCategory {
                            CategoryIconGrid(
                                category: selectedCategory,
                                gridItems: gridItems,
                                onIconSelected: { selectedIconId in
                                    handleIconSelection(selectedIconId)
                                }
                            )
                        } else if let firstCategory = IconRepo.shared.getAllCategories().first {
                            CategoryIconGrid(
                                category: firstCategory,
                                gridItems: gridItems,
                                onIconSelected: { selectedIconId in
                                    handleIconSelection(selectedIconId)
                                }
                            )
                        } else {
                            Text("没有可用的图标分类")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .onAppear {
                        updateGridItems(geo)
                    }
                    .onChange(of: geo.size.width) {
                        updateGridItems(geo)
                    }
                }
            }
        }
        .onAppear {
            iconProvider.refreshCategories()
        }
    }
    
    private func updateGridItems(_ geo: GeometryProxy) {
        let columns = max(Int(geo.size.width / 80), 1)
        gridItems = Array(repeating: .init(.flexible()), count: columns)
    }
    
    private func handleIconSelection(_ iconId: String) {
        iconProvider.selectIcon(iconId)
        
        // 发送图标选择通知
        NotificationCenter.default.post(
            name: Notification.Name("IconSelected"),
            object: nil,
            userInfo: ["iconId": iconId]
        )
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
