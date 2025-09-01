import SwiftUI

/**
 简约Banner模板的示例视图
 用于在模板选择器中展示布局效果
 */
struct MinimalBannerExampleView: View {
    var body: some View {
        VStack(spacing: 8) {
            // 居中的图标
            Circle()
                .fill(LinearGradient(
                    colors: [.green.opacity(0.6), .blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                )
            
            // 居中的文本
            VStack(spacing: 4) {
                Text("Clean Design")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Minimal & Elegant")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.green.opacity(0.05), .blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(8)
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
