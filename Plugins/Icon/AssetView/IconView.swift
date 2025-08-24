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
    
    /// 判断当前图标是否被选中
    private var isSelected: Bool {
        iconProvider.selectedIconId == iconAsset.iconId
    }
    
    var body: some View {
        // 使用IconAsset的可调整大小视图（自动处理本地和远程）
        iconAsset.getResizableIconView(size: 40)
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
                self.iconProvider.selectIcon(iconAsset.iconId)
            }
            .onHover { hovering in
                isHovered = hovering
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
