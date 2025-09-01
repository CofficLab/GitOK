import SwiftUI

/**
 经典Banner模板的修改器视图
 包含经典布局所需的所有独立编辑控件
 */
struct ClassicBannerModifiers: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ClassicTitleEditor()
                ClassicSubTitleEditor()
                ClassicFeaturesEditor()
                ClassicImageEditor()
                ClassicBackgroundEditor()
                ClassicOpacityEditor()
            }
            .padding()
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
