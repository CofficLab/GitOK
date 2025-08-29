import MagicCore
import SwiftUI

/**
 * 图标盒子视图
 * 负责管理仓库来源选择、分类选择和图标展示的整体布局
 * 顶部显示仓库来源tab，左侧显示分类列表，右侧显示图标网格
 */
struct IconBox: View {
    @EnvironmentObject var iconProvider: IconProvider
    @State private var selectedSourceType: IconSourceType = .local
    @State private var availableSources: [IconSourceProtocol] = []
    
    private var repo = IconRepo.shared

    var body: some View {
        VStack(spacing: 0) {
            // 顶部：仓库来源选择tab
            SourceTabs(
                selectedSourceType: $selectedSourceType,
                availableSources: availableSources
            )
            .frame(height: 40)
            
            // 主体内容：左侧分类 + 右侧图标网格
            HStack(spacing: 0) {
                // 左侧：分类列表
                CategoryList(
                    selectedSourceType: selectedSourceType,
                    selectedCategory: iconProvider.selectedCategory
                )
                .frame(width: 200)
                .background(Color(.controlBackgroundColor))
                
                // 分隔线
                Divider()
                    .frame(width: 1)
                
                // 右侧：图标网格
                IconGrid(
                    selectedCategory: iconProvider.selectedCategory
                )
            }
        }
        .onAppear {
            loadAvailableSources()
            ensureDefaultSelection()
        }
    }
    
    /// 加载可用的图标来源
    private func loadAvailableSources() {
        availableSources = repo.getAllIconSources()
    }
    
    /// 确保有默认选择
    private func ensureDefaultSelection() {
        if iconProvider.selectedCategory == nil {
            Task {
                let categories = await repo.getAllCategories(enableRemote: true)
                if let firstCategory = categories.first {
                    await MainActor.run {
                        iconProvider.selectCategory(firstCategory)
                        selectedSourceType = firstCategory.sourceType
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
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
