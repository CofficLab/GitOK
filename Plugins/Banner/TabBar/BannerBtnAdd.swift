import MagicCore
import OSLog
import SwiftData
import SwiftUI

/**
    添加Banner按钮
    提供创建新Banner的功能，直接与BannerRepo交互进行创建操作。
**/
struct BannerBtnAdd: View, SuperThread {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared

    var body: some View {
        if let project = g.project {
            MagicButton.simple(icon: .iconAdd, title: "新建") {
                createBanner(in: project)
            }
            .magicSize(.auto)
        }
    }
    
    /**
        创建新Banner
        直接调用repo层创建Banner，通知由repo层负责发送
        
        ## 参数
        - `project`: 所属项目
    */
    private func createBanner(in project: Project) {
        do {
            let newBanner = try bannerRepo.createBanner(in: project, title: "New Banner")
            
            // 设置为当前选中的Banner
            b.setBanner(newBanner)
            
            m.info("已添加新的Banner文件")
        } catch {
            m.error("创建Banner失败：\(error.localizedDescription)")
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
