import MagicAlert
import OSLog
import SwiftUI

/**
     Banner标签按钮视图
     用于在标签栏中显示单个Banner项目，支持选中状态显示和右键删除操作。

     ## 功能特性
     - 显示Banner标题（如果为空则显示"Untitled"）
     - 支持选中状态的视觉反馈
     - 提供右键删除功能
     - 响应点击切换选中状态
     - 集成删除Banner的完整逻辑
     - 直接与BannerProvider交互，无需外部参数
 **/
struct BannerTab: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var d: DataProvider
    

    /// Banner数据
    let banner: BannerFile

    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared

    /// 检查当前Banner是否为选中状态
    private var isSelected: Bool {
        b.banner.id == banner.id
    }

    var body: some View {
        Image.document.inButtonWithAction {
            guard let project = d.project else {
                return
            }
            
            guard let latest = bannerRepo.getBanner(by: banner.id, from: project) else {
                return
            }
            
            b.setBanner(latest)
        }
        .contextMenu {
            Button(action: { deleteBanner() }) {
                Label("删除", systemImage: "trash")
            }
        }
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

            alert_info("已删除")
        } catch {
            alert_error("删除Banner失败：\(error.localizedDescription)")
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .setInitialTab("Banner")
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .setInitialTab("Banner")
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
