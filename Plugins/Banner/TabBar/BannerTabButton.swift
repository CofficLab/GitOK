import SwiftUI
import MagicCore

/**
    Banner标签按钮视图
    用于在标签栏中显示单个Banner项目，支持选中状态显示和右键菜单操作。
    
    ## 功能特性
    - 显示Banner标题（如果为空则显示"Untitled"）
    - 支持选中状态的视觉反馈
    - 提供右键删除菜单
    - 响应点击切换选中状态
**/
struct BannerTabButton: View {
    /// Banner数据
    let banner: BannerData
    
    /// 当前选中的Banner
    @Binding var selection: BannerData?
    
    var body: some View {
        Button(action: { selection = banner }) {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .padding(4)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(4)

                Text(banner.title.isEmpty ? "Untitled" : banner.title)
                    .font(.callout)
                    .lineLimit(1)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 1 : 0.5)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            BtnDelBanner(banner: banner)
        }
    }
    
    /// 检查当前Banner是否为选中状态
    private var isSelected: Bool {
        selection?.id == banner.id
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideProjectActions()
            .hideTabPicker()
            .hideSidebar()
    }
    .frame(width: 700)
    .frame(height: 1200)
}
