import MagicCore
import SwiftUI
import OSLog

/**
    Banner标签按钮视图
    用于在标签栏中显示单个Banner项目，支持选中状态显示和右键删除操作。
    
    ## 功能特性
    - 显示Banner标题（如果为空则显示"Untitled"）
    - 支持选中状态的视觉反馈
    - 提供右键删除功能
    - 响应点击切换选中状态
    - 集成删除Banner的完整逻辑
**/
struct BannerTab: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    /// Banner数据
    let banner: BannerFile
    
    /// 当前选中的Banner
    @Binding var selection: BannerFile?
    
    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared

    var body: some View {
        MagicButton.simple(action: { selection = banner })
            .magicStyle(selection == banner ? .primary : .secondary)
            .magicShape(.rectangle)
            .magicSize(.mini)
            .magicIcon(.iconDocument)
            .magicTitle(banner.title)
            .contextMenu {
                Button(action: { deleteBanner() }) {
                    Label("删除「\(banner.title.isEmpty ? "Untitled" : banner.title)」", systemImage: "trash")
                }
            }
    }

    /// 检查当前Banner是否为选中状态
    private var isSelected: Bool {
        selection?.id == banner.id
    }
    
    /**
        删除Banner
        直接调用repo层删除Banner，通知由repo层负责发送
    */
    private func deleteBanner() {
        do {
            try bannerRepo.deleteBanner(banner)
            
            // 如果删除的是当前选中的Banner，清除选中状态
            if b.banner.id == banner.id {
                b.clearBanner()
            }
            
            m.info("已删除Banner：\(banner.title.isEmpty ? "Untitled" : banner.title)")
        } catch {
            m.error("删除Banner失败：\(error.localizedDescription)")
        }
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
    .frame(height: 800)
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
    .frame(height: 1000)
}
