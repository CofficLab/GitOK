import SwiftUI
import MagicCore

/**
 简约模板的标题组件
 专门为简约布局设计的标题显示组件
 */
struct MinimalTitle: View {
    @EnvironmentObject var b: BannerProvider
    
    var body: some View {
        Text(b.banner.title)
            .font(.system(size: getTitleSize(), weight: getTitleWeight(), design: .default))
            .foregroundColor(getTitleColor())
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }
    
    private func getTitleSize() -> CGFloat {
        // 从模板数据中获取字体大小
        let template = MinimalBannerTemplate()
        let minimalData = template.restoreData(from: b.banner) as! MinimalBannerData
        return CGFloat(minimalData.titleSize)
    }
    
    private func getTitleWeight() -> Font.Weight {
        // 从模板数据中获取字体粗细
        let template = MinimalBannerTemplate()
        let minimalData = template.restoreData(from: b.banner) as! MinimalBannerData
        return minimalData.titleWeight
    }
    
    private func getTitleColor() -> Color {
        // 优先使用模板特定的颜色，否则使用通用颜色
        let template = MinimalBannerTemplate()
        let minimalData = template.restoreData(from: b.banner) as! MinimalBannerData
        
        if let templateColor = minimalData.titleColor {
            return templateColor
        } else if let bannerColor = b.banner.titleColor {
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
