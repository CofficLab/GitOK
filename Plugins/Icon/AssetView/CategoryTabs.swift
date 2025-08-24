import MagicCore
import SwiftUI

/**
 * 分类标签页组件
 * 负责显示所有可用的图标分类标签页
 * 数据流：IconRepo -> IconCategory -> CategoryTabs
 */
struct CategoryTabs: View {
    @EnvironmentObject var iconProvider: IconProvider
    @EnvironmentObject var m: MagicMessageProvider

    var body: some View {
        HStack(spacing: 8) {
            // 左侧：分类标签页（可滚动）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(iconProvider.availableCategories, id: \.id) { category in
                        CategoryTab(
                            category: category,
                            isSelected: iconProvider.selectedCategory?.id == category.id,
                            onTap: {
                                iconProvider.selectCategory(category)
                            }
                        )
                    }
                }
            }

            // 右侧：功能按钮组
            HStack(spacing: 8) {
                // 换图按钮
                Button(action: changeImage) {
                    Image.add
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("更换图片")
            }
        }
        .onAppear {
            // 确保有选中的分类
            if iconProvider.selectedCategory == nil {
                iconProvider.refreshCategories()
            }
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
                if var icon = iconProvider.currentData {
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
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
