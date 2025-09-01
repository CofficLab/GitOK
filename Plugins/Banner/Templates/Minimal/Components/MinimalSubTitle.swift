import SwiftUI
import MagicCore

/**
 简约模板的副标题组件
 专门为简约布局设计的副标题显示组件
 */
struct MinimalSubTitle: View {
    @EnvironmentObject var b: BannerProvider
    
    var body: some View {
        Text(b.banner.subTitle)
            .font(.system(size: getSubTitleSize(), weight: getSubTitleWeight(), design: .default))
            .foregroundColor(getSubTitleColor())
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }
    
    private func getSubTitleSize() -> CGFloat {
        // 从模板数据中获取字体大小
        let template = MinimalBannerTemplate()
        let minimalData = template.restoreData(from: b.banner) as! MinimalBannerData
        return CGFloat(minimalData.subtitleSize)
    }
    
    private func getSubTitleWeight() -> Font.Weight {
        // 从模板数据中获取字体粗细
        let template = MinimalBannerTemplate()
        let minimalData = template.restoreData(from: b.banner) as! MinimalBannerData
        return minimalData.subtitleWeight
    }
    
    private func getSubTitleColor() -> Color {
        // 优先使用模板特定的颜色，否则使用通用颜色
        let template = MinimalBannerTemplate()
        let minimalData = template.restoreData(from: b.banner) as! MinimalBannerData
        
        if let templateColor = minimalData.subtitleColor {
            return templateColor
        } else if let bannerColor = b.banner.subTitleColor {
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
