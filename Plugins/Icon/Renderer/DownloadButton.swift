import SwiftUI
import MagicCore

/**
 * 单个下载按钮组件
 */
struct DownloadButton: View {
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
        // 主下载按钮
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isDisabled ? .secondary : color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isDisabled ? .secondary : .primary)
                
                Spacer()
            }
            .padding()
            .background(isDisabled ? Color.gray.opacity(0.02) : Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isDisabled ? Color.gray.opacity(0.2) : color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

#Preview("DownloadButton - Enabled") {
    DownloadButton(
        title: "下载 Xcode 格式",
        icon: "xcode",
        color: .blue,
        action: {}
    )
    .padding()
}

#Preview("DownloadButton - Disabled") {
    DownloadButton(
        title: "下载 Xcode 格式",
        icon: "xcode",
        color: .blue,
        action: {},
        isDisabled: true
    )
    .padding()
}
