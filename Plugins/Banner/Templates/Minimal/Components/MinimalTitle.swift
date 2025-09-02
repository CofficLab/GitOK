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
    
    var minimalData: MinimalBannerData? { b.banner.minimalData }
    
    var body: some View {
        Text(minimalData?.title ?? "App Title")
            .font(.system(size: fontSize, weight: .bold, design: .default))
            .foregroundColor(getTitleColor())
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }
    
    private func getTitleColor() -> Color {
        return minimalData?.titleColor ?? .primary
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
