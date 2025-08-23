import SwiftUI
import MagicCore

/**
 * 分类标签页组件
 * 负责显示所有可用的图标分类，支持横向滚动和分类选择
 * 数据流：IconCategoryRepo -> CategoryTabs
 */
struct CategoryTabs: View {
    @EnvironmentObject var iconProvider: IconProvider
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(IconCategoryRepo.shared.categories, id: \.id) { category in
                    CategoryTab(
                        category: category,
                        isSelected: iconProvider.selectedCategory?.id == category.id
                    ) {
                        iconProvider.selectCategory(category.name)
                    }
                }
            }
            .padding(.horizontal)
        }
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
