import SwiftUI

/**
 经典布局的数据模型
 */
struct ClassicBannerData {
    var title: String = "Banner Title"
    var subTitle: String = "Banner SubTitle"
    var features: [String] = []
    var imageId: String? = nil
    var backgroundId: String = "1"
    var inScreen: Bool = false
    var opacity: Double = 1.0
    var titleColor: Color? = nil
    var subTitleColor: Color? = nil
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
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}


