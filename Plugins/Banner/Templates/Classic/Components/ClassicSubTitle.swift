import SwiftUI
import MagicCore

/**
 经典模板的副标题组件
 专门为经典布局设计的副标题显示组件
 */
struct ClassicSubTitle: View {
    @EnvironmentObject var b: BannerProvider
    
    var body: some View {
        Text(b.banner.subTitle)
            .font(.system(size: getSubTitleSize(), weight: .medium, design: .default))
            .foregroundColor(getSubTitleColor())
            .multilineTextAlignment(.leading)
            .lineLimit(3)
    }
    
    private func getSubTitleSize() -> CGFloat {
        // 经典模板使用中等大小的副标题字体
        return 24.0
    }
    
    private func getSubTitleColor() -> Color {
        // 优先使用通用颜色设置
        if let bannerColor = b.banner.subTitleColor {
            return bannerColor
        } else {
            return .secondary
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
