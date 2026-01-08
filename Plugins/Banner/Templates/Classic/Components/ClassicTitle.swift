import SwiftUI


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
    
    var classicData: ClassicBannerData? { b.banner.classicData }
    
    var body: some View {
        Text(classicData?.title ?? "Banner Title")
            .font(.system(size: fontSize, weight: .bold, design: .default))
            .foregroundColor(getTitleColor())
            .multilineTextAlignment(.leading)
            .lineLimit(2)
    }
    
    private func getTitleColor() -> Color {
        return classicData?.titleColor ?? .primary
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

