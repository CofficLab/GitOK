import MagicCore
import SwiftUI

/**
 * 图标网格视图
 * 负责显示图标网格布局和加载状态
 * 支持动态列数调整和滚动加载，优化了左右分栏布局
 */
struct IconGrid: View {
    @EnvironmentObject var iconProvider: IconProvider
    
    @State private var gridItems: [GridItem] = Array(repeating: .init(.flexible()), count: 8)
    @State private var iconAssets: [IconAsset] = []
    @State private var isLoading: Bool = false
    
    let selectedCategory: IconCategoryInfo?
    
    init(selectedCategory: IconCategoryInfo?) {
        self.selectedCategory = selectedCategory
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // 分类标题
                if let category = selectedCategory {
                    VStack(spacing: 8) {
                        HStack {
                            Text(category.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(iconAssets.count) 个图标")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        // 右侧：在分类标题下方放置添加/删除按钮（当来源支持增删时显示）
                        if let sid = category.sourceIdentifier as String?,
                           IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid })?.supportsMutations == true {
                            HStack(spacing: 8) {
                                Button("添加图标…") { addImagesViaPanel() }
                                    .buttonStyle(.bordered)
                                Button("删除图标…") { deleteImagesViaPanel() }
                                    .buttonStyle(.bordered)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.controlBackgroundColor))
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(.separatorColor)),
                        alignment: .bottom
                    )
                }
                
                // 图标网格内容
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("加载图标中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Spacer()
                    }
                } else if iconAssets.isEmpty {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text(selectedCategory == nil ? "请选择一个分类" : "该分类下没有可用的图标")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridItems, spacing: 16) {
                            ForEach(iconAssets) { iconAsset in
                                IconView(iconAsset)
                            }
                        }
                        .padding(16)
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
        .onAppear {
            loadIconAssets()
        }
        .onChange(of: selectedCategory) {
            loadIconAssets()
        }
    }
    
    /// 更新网格列数
    private func updateGridItems(_ geo: GeometryProxy) {
        let availableWidth = geo.size.width - 32 // 减去左右padding
        let itemWidth: CGFloat = 60 // 每个图标项的宽度
        let spacing: CGFloat = 16 // 列间距
        let columns = max(Int((availableWidth + spacing) / (itemWidth + spacing)), 1)
        gridItems = Array(repeating: .init(.flexible()), count: columns)
    }
    
    /// 加载图标资源
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

    /// 通过文件选择器添加图片
    private func addImagesViaPanel() {
        guard let sid = selectedCategory?.sourceIdentifier,
              IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid })?.supportsMutations == true else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
        panel.begin { response in
            guard response == .OK else { return }
            let urls = panel.urls
            Task { @MainActor in
                var okCount = 0
                for url in urls {
                    if let data = try? Data(contentsOf: url) {
                        if iconProvider.addImageToProjectLibrary(data: data, filename: url.lastPathComponent) {
                            okCount += 1
                        }
                    }
                }
                print("[IconGrid] addImagesViaPanel done: \(okCount)/\(urls.count)")
            }
        }
    }

    /// 通过文件选择器删除图片
    private func deleteImagesViaPanel() {
        guard let sid = selectedCategory?.sourceIdentifier,
              IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid })?.supportsMutations == true else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
        panel.begin { response in
            guard response == .OK else { return }
            let urls = panel.urls
            Task { @MainActor in
                var okCount = 0
                for url in urls {
                    if iconProvider.deleteImageFromProjectLibrary(filename: url.lastPathComponent) {
                        okCount += 1
                    }
                }
                print("[IconGrid] deleteImagesViaPanel done: \(okCount)/\(urls.count)")
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
    .frame(height: 1200)
}
