import SwiftUI
import MagicCore

/**
 * Banner单个功能特性纯显示组件
 * 只负责显示单个功能特性文本，不包含任何编辑功能
 */
struct Feature: View {
    let title: String

    var body: some View {
        Text(title)
            .padding(40)
            .font(.system(size: 80))
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 48)
                    .fill(.blue.opacity(0.3))
            )
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
    .frame(width: 1200)
    .frame(height: 1200)
}
