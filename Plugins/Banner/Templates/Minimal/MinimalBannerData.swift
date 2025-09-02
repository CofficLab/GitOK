import SwiftUI

/**
 简约布局的数据模型
 */
struct MinimalBannerData {
    var title: String = "App Title"
    var imageId: String? = nil
    var backgroundId: String = "1"
    var inScreen: Bool = false
    var opacity: Double = 1.0
    var titleColor: Color? = nil
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


