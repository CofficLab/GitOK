import SwiftUI

/**
 简约Banner模板的修改器视图
 简化版的编辑控件，只包含核心功能
 */
struct MinimalBannerModifiers: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TitleEditor()
                SubTitleEditor()
                ImageEditor()
                
                GroupBox("背景设置") {
                    Backgrounds()
                }
                
                OpacityEditor()
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
