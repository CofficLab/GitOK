import MagicCore
import SwiftUI

/**
 * 图标盒子视图
 * 负责管理分类选择和图标展示的整体布局
 * 使用独立的 IconGridView 组件显示图标网格
 */
struct IconBox: View {
    @EnvironmentObject var iconProvider: IconProvider

    private var repo = IconRepo.shared

    var body: some View {
        VStack(spacing: 0) {
            // 分类标签页
            CategoryTabs()
                .frame(height: 32)

            // 图标网格
            IconGrid(
                selectedCategory: iconProvider.selectedCategory
            )
        }
        .onAppear {
            // 确保有选中的分类，如果没有则选择第一个
            if iconProvider.selectedCategory == nil {
                Task {
                    let categories = await repo.getAllCategories(enableRemote: true)
                    if let firstCategory = categories.first {
                        await MainActor.run {
                            iconProvider.selectCategory(firstCategory)
                        }
                    }
                }
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
