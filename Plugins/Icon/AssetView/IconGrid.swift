import SwiftUI
import MagicCore

/**
 * 分类图标网格组件
 * 负责展示指定分类下的所有图标
 * 数据流：IconCategory -> IconAsset List（本地分类兼容）
 */
struct IconGrid: View {
    let category: IconCategory
    let gridItems: [GridItem]
    
    /// 缓存图标资源，避免重复创建
    @State private var iconAssets: [IconAsset] = []
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 12) {
            ForEach(iconAssets, id: \.id) { iconAsset in
                IconView(
                    iconAsset: iconAsset
                )
            }
        }
        .padding(.horizontal)
        .onAppear {
            loadIconAssets()
        }
        .onChange(of: category.id) {
            loadIconAssets()
        }
    }
    
    private func loadIconAssets() {
        Task {
            iconAssets = await category.getAllIconAssets()
        }
    }
}

/**
 * 统一分类图标网格组件
 * 负责展示指定统一分类下的所有图标
 * 数据流：IconCategory -> IconAsset List
 */
struct UnifiedIconGrid: View {
    let category: IconCategory
    let gridItems: [GridItem]
    
    /// 缓存图标资源，避免重复创建
    @State private var iconAssets: [IconAsset] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 12) {
            ForEach(iconAssets, id: \.id) { iconAsset in
                IconView(iconAsset: iconAsset)
            }
        }
        .padding(.horizontal)
        .onAppear {
            loadIconAssets()
        }
        .onChange(of: category.id) {
            loadIconAssets()
        }
    }
    
    private func loadIconAssets() {
        isLoading = true
        
        Task {
            let assets = await IconRepo.shared.getIcons(for: category)
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
