import SwiftUI
import MagicCore

/**
 简约模板的标题组件
 专门为简约布局设计的标题显示组件
 */
struct MinimalTitle: View {
    @EnvironmentObject var b: BannerProvider
    
    var fontSize: CGFloat = 48
    
    init(fontSize: CGFloat) {
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(b.banner.title)
            .font(.system(size: fontSize, weight: .bold, design: .default))
            .foregroundColor(getTitleColor())
            .multilineTextAlignment(.center)
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
