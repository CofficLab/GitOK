import SwiftUI
import MagicCore

/**
 经典模板的图片组件
 专门为经典布局设计的图片显示组件
 */
struct ClassicImage: View {
    @EnvironmentObject var b: BannerProvider
    
    let inScreen: Bool = true
    
    var body: some View {
        b.banner.getImage()
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: getCornerRadius()))
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
    
    private func getCornerRadius() -> CGFloat {
        // 经典模板使用适中的圆角
        return 12.0
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 800)
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
