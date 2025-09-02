import SwiftUI
import MagicCore

/**
 简约模板的标题组件
 专门为简约布局设计的标题显示组件
 */
struct MinimalTitle: View {
    @EnvironmentObject var b: BannerProvider
    
    var fontSize: CGFloat = 48
    
    init(fontSize: CGFloat = 48) {
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(b.banner.title)
            .font(.system(size: fontSize))
            .multilineTextAlignment(.center)
            .lineLimit(2)
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
