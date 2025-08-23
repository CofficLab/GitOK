import SwiftUI
import MagicCore

/**
 * 分类标签页组件
 * 负责显示所有可用的图标分类，支持横向滚动和分类选择
 * 数据流：IconCategoryRepo -> CategoryTabs
 */
struct CategoryTabs: View {
    @EnvironmentObject var iconProvider: IconProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(IconRepo.shared.getAllCategories(), id: \.id) { category in
                    CategoryTab(
                        category: category,
                        isSelected: iconProvider.selectedCategory?.id == category.id
                    ) {
                        iconProvider.selectCategory(category.name)
                    }
                }
                
                // 换图按钮 - 作为分类标签页的最后一个选项
                Button(action: changeImage) {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.badge.plus")
                            .font(.caption)
                        Text("换图")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("更换当前图标的图片")
            }
            .padding(.horizontal)
        }
    }
    
    private func changeImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        panel.message = "选择新的图片文件"
        panel.prompt = "选择图片"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                if var icon = iconProvider.currentModel {
                    try icon.updateImageURL(url)
                    m.success("图片已更新")
                } else {
                    m.error("没有找到可以更新的图标")
                }
            } catch {
                m.error("更新图片失败：\(error.localizedDescription)")
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
