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
            // 基础背景
            getBackgroundColor()
                .opacity(getOpacity())
            
            // 简约模板特有的渐变效果
            LinearGradient(
                gradient: Gradient(colors: [
                    getBackgroundColor().opacity(0.8),
                    getBackgroundColor().opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(getOpacity())
        }
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
