import MagicCore
import SwiftUI

/**
 * 分类标签页组件
 * 负责显示所有可用的图标分类标签页
 * 基于新架构使用 IconCategoryInfo
 */
struct CategoryTabs: View {
    @EnvironmentObject var iconProvider: IconProvider

    @State private var categories: [IconCategoryInfo] = []

    var body: some View {
        // 分类标签页（可滚动）
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(categories, id: \.id) { category in
                    CategoryTab(category)
                }
            }
        }
        .background(.yellow.opacity(0.1))
        .onAppear {
            Task {
                self.categories = await IconRepo.shared.getAllCategories(enableRemote: true)
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
