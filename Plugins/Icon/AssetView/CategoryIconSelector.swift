import SwiftUI
import MagicCore

/**
 * 分类图标选择器组件
 * 专门用于图标选择场景，提供简化的选择界面
 * 数据流：IconRepo -> UnifiedIconCategory -> IconAsset Selection
 */
struct CategoryIconSelector: View {
    @EnvironmentObject var iconProvider: IconProvider
    @EnvironmentObject var messageProvider: MagicMessageProvider
    
    @State private var gridItems: [GridItem] = Array(repeating: .init(.flexible()), count: 8)
    @State private var iconAssets: [IconAsset] = []
    @State private var isLoading: Bool = false
    
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
            if isLoading {
                ProgressView("加载图标中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else if iconAssets.isEmpty {
                Text("没有可用的图标")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVGrid(columns: gridItems, spacing: 12) {
                    ForEach(iconAssets, id: \.id) { iconAsset in
                        IconView(iconAsset: iconAsset)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            setupGrid()
            iconProvider.refreshCategories()
        }
        .onChange(of: iconProvider.selectedCategory) {
            loadIconAssets()
        }
    }
    
    private func setupGrid() {
        gridItems = Array(repeating: .init(.flexible()), count: 8)
    }
    
    private func loadIconAssets() {
        guard let selectedCategory = iconProvider.selectedCategory else {
            iconAssets = []
            return
        }
        
        isLoading = true
        
        Task {
            let assets = await IconRepo.shared.getIcons(for: selectedCategory)
            await MainActor.run {
                self.iconAssets = assets
                self.isLoading = false
            }
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
