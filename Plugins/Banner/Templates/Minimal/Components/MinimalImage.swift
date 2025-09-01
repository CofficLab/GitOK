import SwiftUI
import MagicCore

/**
 简约模板的图片组件
 专门为简约布局设计的图片显示组件
 */
struct MinimalImage: View {
    @EnvironmentObject var b: BannerProvider
    let device: Device
    
    var body: some View {
        b.banner.getImage()
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: getCornerRadius()))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func getCornerRadius() -> CGFloat {
        // 简约模板使用较大的圆角
        return 16.0
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
    .frame(width: 800)
    .frame(height: 1000)
}
