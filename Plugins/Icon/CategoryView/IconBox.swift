import MagicCore
import SwiftUI

/**
 * 图标盒子视图
 * 负责管理分类选择和图标展示的整体布局
 * 数据流：IconCategoryRepo -> IconCategory -> IconAsset List
 */
struct IconBox: View {
    @EnvironmentObject var iconProvider: IconProvider
    @State private var gridItems: [GridItem] = Array(repeating: .init(.flexible()), count: 10)
    
    var body: some View {
        VStack(spacing: 0) {
            // 分类标签页
            CategoryTabs()
            
            Divider()
                .padding(.bottom,2)
                .padding(.top, 2)
            
            // 图标网格
            GeometryReader { geo in
                ScrollView {
                    VStack {
                        if iconProvider.isUsingRemoteRepo {
                            // 显示远程图标网格
                            RemoteIconGrid(
                                gridItems: gridItems
                            )
                        } else if let selectedCategory = iconProvider.selectedCategory {
                            // 显示本地图标网格
                            IconGrid(
                                category: selectedCategory,
                                gridItems: gridItems
                            )
                        } else if let firstCategory = AppIconRepo.shared.getAllCategories().first {
                            IconGrid(
                                category: firstCategory,
                                gridItems: gridItems
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
        let columns = max(Int(geo.size.width / 60), 1)
        gridItems = Array(repeating: .init(.flexible()), count: columns)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
