import SwiftUI
import MagicCore

/**
 * 分类图标项组件
 * 负责显示单个图标，支持选中状态、悬停效果和点击事件
 * 数据流：IconAsset -> UI展示
 */
struct IconView: View {
    let iconAsset: IconAsset
    
    @EnvironmentObject var iconProvider: IconProvider
    @State private var isHovered = false
    @State private var loadedImage: Image?
    @State private var isLoading = false
    
    /// 判断当前图标是否被选中
    private var isSelected: Bool {
        iconProvider.selectedIconId == iconAsset.iconId
    }

    init(_ iconAsset: IconAsset) {
        self.iconAsset = iconAsset
    }
    
    var body: some View {
        Group {
            if let loadedImage = loadedImage {
                // 显示已加载的图片
                loadedImage
                    .resizable()
                    .frame(width: 40, height: 40)
            } else if isLoading {
                // 显示加载状态
                ProgressView()
                    .frame(width: 40, height: 40)
            } else {
                // 显示占位符
                Image(systemName: "photo")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.secondary)
            }
        }
        .background(
            Group {
                if isSelected {
                    // 选中状态：蓝色背景
                    Color.accentColor.opacity(0.3)
                } else if isHovered {
                    // 悬停状态：浅色背景
                    Color.accentColor.opacity(0.1)
                } else {
                    // 默认状态：透明背景
                    Color.clear
                }
            }
        )
        .overlay(
            // 选中状态显示蓝色边框
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .cornerRadius(8)
        .contentShape(Rectangle()) // 确保整个矩形区域都能响应点击
        .onTapGesture {
            self.iconProvider.selectIcon(iconAsset.iconId)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            loadIconImage()
        }
    }
    
    /// 异步加载图标图片
    @MainActor
    private func loadIconImage() {
        isLoading = true
        Task {
            let image = await iconAsset.getImage()
            loadedImage = image
            isLoading = false
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
