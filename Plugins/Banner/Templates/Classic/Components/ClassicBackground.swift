import SwiftUI
import MagicCore

/**
 经典模板的背景组件
 专门为经典布局设计的背景显示组件
 */
struct ClassicBackground: View {
    @EnvironmentObject var b: BannerProvider
    
    private var backgroundId: String {
        return b.banner.classicData?.backgroundId ?? "1"
    }

    private var opacity: Double {
        return b.banner.classicData?.opacity ?? 1
    }
    
    var body: some View {
        ZStack {
            // 使用 MagicBackgroundGroup 提供的背景
            if let gradientName = MagicBackgroundGroup.GradientName(rawValue: backgroundId) {
                MagicBackgroundGroup(for: gradientName)
                    .opacity(opacity)
            } else {
                // 如果背景ID无效，使用默认背景
                Color.blue.opacity(opacity)
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .setInitialTab(BannerPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .setInitialTab(BannerPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
