import MagicCore
import SwiftUI

/**
 * 图标网格视图
 * 负责显示图标网格布局和加载状态
 * 支持动态列数调整和滚动加载
 */
struct IconGrid: View {
    @State private var gridItems: [GridItem] = Array(repeating: .init(.flexible()), count: 10)
    @State private var iconAssets: [IconAsset] = []
    @State private var isLoading: Bool = false
    
    let selectedCategory: IconCategoryInfo?
    let enableRemote: Bool
    
    init(selectedCategory: IconCategoryInfo?, enableRemote: Bool) {
        self.selectedCategory = selectedCategory
        self.enableRemote = enableRemote
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack {
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
                            ForEach(iconAssets) { iconAsset in
                                IconView(iconAsset)
                            }
                        }
                    }
                }
                .onAppear {
                    updateGridItems(geo)
                }
                .onChange(of: geo.size.width) {
                    updateGridItems(geo)
                }
            }
        }
        .onAppear {
            loadIconAssets()
        }
        .onChange(of: selectedCategory) {
            loadIconAssets()
        }
    }
    
    private func updateGridItems(_ geo: GeometryProxy) {
        let columns = max(Int(geo.size.width / 60), 1)
        gridItems = Array(repeating: .init(.flexible()), count: columns)
    }
    
    private func loadIconAssets() {
        guard let selectedCategory = selectedCategory else {
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
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
