import SwiftUI
import MagicCore

/**
 * Banner下载按钮基础组件
 * 为Banner提供统一的下载按钮样式和行为
 */
struct BannerDownloadButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let isDisabled: Bool
    
    /// 初始化方法
    /// - Parameters:
    ///   - title: 按钮标题
    ///   - icon: 按钮图标
    ///   - color: 按钮颜色
    ///   - action: 点击动作
    ///   - isDisabled: 是否禁用，默认为false
    init(title: String, icon: String, color: Color, action: @escaping () -> Void, isDisabled: Bool = false) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDisabled ? .secondary : color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isDisabled ? .secondary : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isDisabled ? Color.gray.opacity(0.02) : Color.gray.opacity(0.05))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isDisabled ? Color.gray.opacity(0.2) : color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
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
