import SwiftUI
import MagicCore

/**
 * 分类图标选择器组件
 * 专门用于图标选择场景，提供简化的选择界面
 * 数据流：IconCategoryRepo -> IconCategory -> IconAsset Selection
 */
struct CategoryIconSelector: View {
    @EnvironmentObject var iconProvider: IconProvider
    @EnvironmentObject var messageProvider: MagicMessageProvider
    
    @State private var gridItems: [GridItem] = Array(repeating: .init(.flexible()), count: 8)
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("选择图标")
                    .font(.headline)
                Spacer()
            }
            
            // 分类标签页
            CategoryTabs()
            
            // 图标网格
            if let selectedCategory = iconProvider.selectedCategory {
                IconGrid(
                    category: selectedCategory,
                    gridItems: gridItems
                )
            } else if let firstCategory = IconRepo.shared.getAllCategories().first {
                IconGrid(
                    category: firstCategory,
                    gridItems: gridItems
                )
            } else {
                Text("没有可用的图标分类")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .onAppear {
            setupGrid()
        }
    }
    
    private func setupGrid() {
        gridItems = Array(repeating: .init(.flexible()), count: 8)
    }
    
    private func handleIconSelection(_ iconId: String) {
        guard iconProvider.currentModel != nil else {
            messageProvider.error("请先选择一个图标文件")
            return
        }
        
        iconProvider.selectIcon(iconId)
        messageProvider.info("图标已更新")
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
