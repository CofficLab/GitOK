import SwiftUI
import MagicCore

/**
 * 分类图标网格组件
 * 负责展示指定分类下的所有图标
 * 数据流：IconCategory -> IconAsset List
 */
struct IconGrid: View {
    let category: IconCategory
    let gridItems: [GridItem]
    let onIconSelected: (String) -> Void
    
    /// 缓存图标资源，避免重复创建
    @State private var iconAssets: [IconAsset] = []
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 12) {
            ForEach(iconAssets, id: \.id) { iconAsset in
                IconView(
                    iconAsset: iconAsset,
                    onTap: {
                        onIconSelected(iconAsset.iconId)
                    }
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
        // 只在分类变化时重新加载图标资源
        iconAssets = category.getAllIconAssets()
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
