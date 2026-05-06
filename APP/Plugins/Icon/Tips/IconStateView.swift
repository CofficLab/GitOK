import SwiftUI

/**
 * 通用状态视图组件
 * 用于显示各种状态：加载中、错误、空状态等
 * 统一了frame设置和样式，减少代码重复
 */
struct IconStateView: View {
    let icon: String?
    let title: String
    let subtitle: String?
    let color: Color
    let size: CGFloat
    let showProgress: Bool
    let showRetryButton: Bool
    let onRetry: (() -> Void)?
    
    init(
        icon: String?,
        title: String,
        subtitle: String? = nil,
        color: Color = .secondary,
        size: CGFloat,
        showProgress: Bool = false,
        showRetryButton: Bool = false,
        onRetry: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.size = size
        self.showProgress = showProgress
        self.showRetryButton = showRetryButton
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if showProgress {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if showRetryButton, let onRetry = onRetry {
                Button("重试", action: onRetry)
                    .buttonStyle(.bordered)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
