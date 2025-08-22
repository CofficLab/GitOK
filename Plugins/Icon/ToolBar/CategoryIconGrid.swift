import SwiftUI
import MagicCore

/**
 * 分类图标网格组件
 * 用于以网格形式显示指定分类下的所有图标
 */
struct CategoryIconGrid: View {
    let category: String
    let gridItems: [GridItem]
    let onIconSelected: (Int) -> Void
    
    @EnvironmentObject var iconProvider: IconProvider
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 12) {
            if let categoryModel = iconProvider.getCategory(byName: category) {
                ForEach(categoryModel.iconIds, id: \.self) { iconId in
                    CategoryIconItem(
                        category: category,
                        iconId: iconId,
                        onTap: {
                            onIconSelected(iconId)
                        }
                    )
                }
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
