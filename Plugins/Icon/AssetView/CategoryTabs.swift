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

    @State private var cateogories: [IconCategory] = []

    var body: some View {
        HStack(spacing: 0) {
            // 左侧：分类标签页（可滚动）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(cateogories, id: \.id) { category in
                        CategoryTab(category)
                    }
                }
            }
            .background(.yellow.opacity(0.1))

            // 右侧：功能按钮组
            HStack(spacing: 8) {
                // 网络仓库启用/禁用按钮
                Button(action: {
                    iconProvider.toggleRemoteRepository()
                }) {
                    Image(systemName: iconProvider.enableRemoteRepository ? "network" : "network.slash")
                        .font(.title3)
                        .foregroundColor(iconProvider.enableRemoteRepository ? .green : .red)
                }
                .buttonStyle(.plain)
                .help(iconProvider.enableRemoteRepository ? "禁用网络仓库" : "启用网络仓库")

                // 换图按钮
                Button(action: changeImage) {
                    Image.add
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("更换图片")
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(.purple.opacity(0.2))
                    .shadow(color: .black.opacity(0.8), radius: 4, x: -2, y: 0)
            )
        }
        .onAppear {
            Task {
                self.cateogories = await IconRepo.shared.getAllCategories()
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
