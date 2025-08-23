import SwiftUI
import MagicCore

/**
 * 分类图标网格组件
 * 负责展示指定分类下的所有图标
 * 数据流：IconCategory -> IconAsset List
 */
struct CategoryIconGrid: View {
    let category: IconCategory
    let gridItems: [GridItem]
    let onIconSelected: (String) -> Void
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 12) {
            ForEach(category.getAllIconAssets(), id: \.id) { iconAsset in
                IconView(
                    iconAsset: iconAsset,
                    onTap: {
                        onIconSelected(iconAsset.iconId)
                    }
                )
            }
        }
        .padding(.horizontal)
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
