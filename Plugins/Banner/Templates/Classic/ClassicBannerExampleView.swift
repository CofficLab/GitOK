import SwiftUI

/**
 经典Banner模板的示例视图
 用于在模板选择器中展示布局效果
 */
struct ClassicBannerExampleView: View {
    var body: some View {
        HStack(spacing: 8) {
            // 左侧文本区域
            VStack(alignment: .leading, spacing: 6) {
                Text("App Name")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Amazing Description")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    FeatureItem(text: "• Feature One")
                    FeatureItem(text: "• Feature Two")
                    FeatureItem(text: "• Feature Three")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 右侧图片区域
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 40, height: 30)
                .overlay(
                    Image(systemName: "app.fill")
                        .font(.system(size: 16))
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

private struct FeatureItem: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 7))
            .foregroundColor(.secondary)
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
