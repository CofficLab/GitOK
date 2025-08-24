import MagicCore
import SwiftUI

/**
 * 图标盒子视图
 * 负责管理分类选择和图标展示的整体布局
 * 数据流：IconRepo -> IconCategory -> IconAsset List
 */
struct IconBox: View {
    @EnvironmentObject var iconProvider: IconProvider
    @State private var gridItems: [GridItem] = Array(repeating: .init(.flexible()), count: 10)
    @State private var iconAssets: [IconAsset] = []
    @State private var isLoading: Bool = false
    
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
                        if isLoading {
                            ProgressView("加载图标中...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                        } else if iconAssets.isEmpty {
                            Text("没有可用的图标")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVGrid(columns: gridItems, spacing: 12) {
                                ForEach(iconAssets, id: \.id) { iconAsset in
                                    IconView(iconAsset: iconAsset)
                                }
                            }
                            .padding(.horizontal)
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
            // 确保有选中的分类，如果没有则选择第一个
            if iconProvider.selectedCategory == nil {
                Task {
                    let categories = await IconRepo.shared.getAllCategories()
                    if let firstCategory = categories.first {
                        await MainActor.run {
                            iconProvider.selectCategory(firstCategory)
                        }
                    }
                }
            } else {
                // 如果已有选中的分类，直接加载图标
                loadIconAssets()
            }
        }
        .onChange(of: iconProvider.selectedCategory) {
            loadIconAssets()
        }
    }
    
    private func updateGridItems(_ geo: GeometryProxy) {
        let columns = max(Int(geo.size.width / 60), 1)
        gridItems = Array(repeating: .init(.flexible()), count: columns)
    }
    
    private func loadIconAssets() {
        guard let selectedCategory = iconProvider.selectedCategory else {
            iconAssets = []
            return
        }
        
        isLoading = true
        
        Task {
            let assets = await IconRepo.shared.getIcons(for: selectedCategory)
            await MainActor.run {
                self.iconAssets = assets
                self.isLoading = false
            }
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
