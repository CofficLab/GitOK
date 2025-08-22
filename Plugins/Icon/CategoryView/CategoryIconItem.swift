import SwiftUI
import MagicCore

/**
 * 分类图标项组件
 * 用于显示单个图标，支持选中状态、悬停效果和点击事件
 */
struct CategoryIconItem: View {
    let category: String
    let iconId: Int
    let onTap: () -> Void
    
    @EnvironmentObject var iconProvider: IconProvider
    @State private var image = Image(systemName: "photo")
    @State private var isHovered = false
    
    /// 判断当前图标是否被选中
    private var isSelected: Bool {
        iconProvider.selectedIconId == iconId
    }
    
    var body: some View {
        image
            .resizable()
            .frame(width: 60, height: 60)
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
            .onTapGesture {
                onTap()
            }
            .onHover { hovering in
                isHovered = hovering
            }
            .onAppear {
                DispatchQueue.global().async {
                    let thumbnail = IconItem.getThumbnail(category: category, iconId: iconId)
                    DispatchQueue.main.async {
                        self.image = thumbnail
                    }
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
