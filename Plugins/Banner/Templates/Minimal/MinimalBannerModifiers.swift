import SwiftUI

/**
 简约Banner模板的修改器视图
 包含简约布局所需的所有独立编辑控件
 */
struct MinimalBannerModifiers: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MinimalTitleEditor()
                MinimalImageEditor()
                MinimalBackgroundEditor()
                MinimalOpacityEditor()
            }
            .padding()
        }
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
