import SwiftUI

/**
 简约Banner模板的修改器视图
 简化版的编辑控件，专为简约风格定制
 */
struct MinimalBannerModifiers: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MinimalTitleEditor()
                ClassicSubTitleEditor() // 暂时复用，将来可以创建MinimalSubTitleEditor
                MinimalImageEditor()
                ClassicBackgroundEditor() // 暂时复用，将来可以创建MinimalBackgroundEditor
                ClassicOpacityEditor() // 暂时复用，将来可以创建MinimalOpacityEditor
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
