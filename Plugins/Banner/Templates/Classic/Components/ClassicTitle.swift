import SwiftUI
import MagicCore

/**
 经典模板的标题组件
 专门为经典布局设计的标题显示组件
 */
struct ClassicTitle: View {
    @EnvironmentObject var b: BannerProvider
    
    var fontSize: CGFloat = 48
    
    init(fontSize: CGFloat) {
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(b.banner.title)
            .font(.system(size: fontSize, weight: .bold, design: .default))
            .foregroundColor(getTitleColor())
            .multilineTextAlignment(.leading)
            .lineLimit(2)
    }
    
    private func getTitleColor() -> Color {
        // 优先使用通用颜色设置
        if let bannerColor = b.banner.titleColor {
            return bannerColor
        } else {
            return .primary
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
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
