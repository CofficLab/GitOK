import SwiftUI
import MagicCore

/**
 经典模板的特性列表组件
 专门为经典布局设计的特性显示组件
 */
struct ClassicFeatures: View {
    @EnvironmentObject var b: BannerProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(b.banner.features, id: \.self) { feature in
                HStack(spacing: 8) {
                    // 经典模板使用圆点作为特性标记
                    Circle()
                        .fill(getFeatureColor())
                        .frame(width: 6, height: 6)
                    
                    Text(feature)
                        .font(.system(size: getFeatureSize(), weight: .regular, design: .default))
                        .foregroundColor(getFeatureTextColor())
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func getFeatureSize() -> CGFloat {
        // 经典模板使用中等大小的特性文字
        return 16.0
    }
    
    private func getFeatureColor() -> Color {
        // 特性标记使用主题色
        return getBackgroundColor()
    }
    
    private func getFeatureTextColor() -> Color {
        // 特性文字使用次要颜色
        return .secondary
    }
    
    private func getBackgroundColor() -> Color {
        // 根据背景ID返回对应的颜色
        switch b.banner.backgroundId {
        case "1":
            return Color.blue
        case "2":
            return Color.green
        case "3":
            return Color.purple
        case "4":
            return Color.orange
        case "5":
            return Color.red
        default:
            return Color.blue
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
