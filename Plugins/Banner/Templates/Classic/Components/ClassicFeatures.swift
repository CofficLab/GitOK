
import SwiftUI

/**
 经典模板的特性列表组件
 专门为经典布局设计的特性显示组件
 */
struct ClassicFeatures: View {
    @EnvironmentObject var b: BannerProvider

    var fontSize: CGFloat = 24

    var features: [String] {
        return b.banner.classicData?.features ?? []
    }

    init(fontSize: CGFloat) {
        self.fontSize = fontSize
    }

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            ForEach(features, id: \.self) { feature in
                Text(feature)
                    .font(.system(size: fontSize))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity)
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
