import SwiftUI
import MagicCore

struct CategoryIconSelector: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var m: MagicMessageProvider
    
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
            if let selectedCategory = i.selectedCategory {
                CategoryIconGrid(
                    category: selectedCategory.name,
                    gridItems: gridItems,
                    onIconSelected: { selectedIconId in
                        handleIconSelection(selectedIconId)
                    }
                )
            } else if let firstCategory = i.availableCategories.first {
                CategoryIconGrid(
                    category: firstCategory,
                    gridItems: gridItems,
                    onIconSelected: { selectedIconId in
                        handleIconSelection(selectedIconId)
                    }
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
    
    private func handleIconSelection(_ iconId: Int) {
        guard i.currentModel != nil else {
            m.error("请先选择一个图标文件")
            return
        }
        
        // 使用IconProvider的统一方法选择图标
        i.selectIcon(iconId)
        m.info("图标已更新")
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
