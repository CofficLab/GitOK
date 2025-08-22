import SwiftUI
import MagicCore

/**
 * 分类标签页组件
 * 用于显示所有可用的图标分类，支持横向滚动和分类选择
 */
struct CategoryTabs: View {
    @EnvironmentObject var iconProvider: IconProvider
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(iconProvider.iconRepo.categories, id: \.name) { category in
                    CategoryTab(
                        title: category.name,
                        isSelected: iconProvider.selectedCategory?.name == category.name,
                        iconCount: category.iconCount
                    ) {
                        iconProvider.selectCategory(category.name)
                    }
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            // 确保分类列表是最新的
            iconProvider.refreshCategories()
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
