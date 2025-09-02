import SwiftUI
import MagicCore

/**
 简约模板的背景组件
 专门为简约布局设计的背景显示组件
 */
struct MinimalBackground: View {
    @EnvironmentObject var b: BannerProvider
    
    var body: some View {
        ZStack {
            // 使用 MagicBackgroundGroup 提供的背景
            if let gradientName = MagicBackgroundGroup.GradientName(rawValue: b.banner.backgroundId) {
                MagicBackgroundGroup(for: gradientName)
                    .opacity(getOpacity())
            } else {
                // 如果背景ID无效，使用默认背景
                Color.blue.opacity(getOpacity())
            }
        }
    }
    
    private func getOpacity() -> Double {
        return b.banner.opacity
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
