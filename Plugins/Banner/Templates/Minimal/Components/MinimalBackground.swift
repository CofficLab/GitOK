import SwiftUI
import MagicCore

/**
 简约模板的背景组件
 专门为简约布局设计的背景显示组件
 */
struct MinimalBackground: View {
    @EnvironmentObject var b: BannerProvider
    
    var minimalData: MinimalBannerData? { b.banner.minimalData }
    
    var body: some View {
        ZStack {
            // 使用 MagicBackgroundGroup 提供的背景
            if let data = minimalData,
               let gradientName = MagicBackgroundGroup.GradientName(rawValue: data.backgroundId) {
                MagicBackgroundGroup(for: gradientName)
                    .opacity(getOpacity())
            } else {
                // 如果背景ID无效，使用默认背景
                Color.blue.opacity(getOpacity())
            }
        }
    }
    
    private func getOpacity() -> Double {
        return minimalData?.opacity ?? 1.0
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
