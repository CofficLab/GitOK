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
