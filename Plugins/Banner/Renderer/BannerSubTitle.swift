import SwiftUI
import MagicCore

/**
 * Banner副标题纯显示组件
 * 只负责显示副标题文本，不包含任何编辑功能
 * 数据变化时自动重新渲染
 */
struct BannerSubTitle: View {
    @EnvironmentObject var b: BannerProvider
    
    var body: some View {
        Text(b.banner.subTitle.isEmpty ? "副标题" : b.banner.subTitle)
            .font(.system(size: 100))
            .foregroundColor(b.banner.subTitleColor ?? .white)
            .multilineTextAlignment(.center)
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
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
