import SwiftUI

/**
 简约Banner模板的示例视图
 用于在模板选择器中展示布局效果
 */
struct MinimalBannerExampleView: View {
    var body: some View {
        VStack(spacing: 8) {
            // 居中的标题
            Text("App Name")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
            
            // 居中的图片
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "app.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                )
        }
        .padding(8)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(8)
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
