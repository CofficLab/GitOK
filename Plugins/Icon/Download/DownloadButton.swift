
import SwiftUI

/**
 * 单个下载按钮组件
 * 支持自定义内容或使用默认布局
 */
struct DownloadButton<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let isDisabled: Bool
    let customContent: (() -> Content)?

    /// 默认初始化方法（保持向后兼容）
    /// - Parameters:
    ///   - title: 按钮标题
    ///   - icon: 按钮图标
    ///   - color: 按钮颜色
    ///   - action: 点击动作
    ///   - isDisabled: 是否禁用，默认为false
    init(title: String, icon: String, color: Color, action: @escaping () -> Void, isDisabled: Bool = false) where Content == EmptyView {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
        self.isDisabled = isDisabled
        self.customContent = nil
    }

    /// 自定义内容初始化方法
    /// - Parameters:
    ///   - title: 按钮标题
    ///   - icon: 按钮图标
    ///   - color: 按钮颜色
    ///   - action: 点击动作
    ///   - isDisabled: 是否禁用，默认为false
    ///   - content: 自定义内容闭包
    init(title: String, icon: String, color: Color, action: @escaping () -> Void, isDisabled: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
        self.isDisabled = isDisabled
        self.customContent = content
    }

    var body: some View {
        VStack(spacing: 0) {
            // 主下载按钮
            Button(action: action) {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(isDisabled ? .secondary : color)
                            .frame(width: 24)

                        Text(title)
                            .font(.headline)
                            .foregroundColor(isDisabled ? .secondary : .primary)
                        
                        Spacer()
                    }

                    // 自定义内容区域
                    if let customContent = customContent {
                        customContent()
                    }
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
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
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

#Preview("DownloadButton - Custom Content") {
    DownloadButton(
        title: "下载 Xcode 格式",
        icon: "applelogo",
        color: .blue,
        action: {}
    ) {
        HStack {
            Picker("", selection: .constant("Xcode 16")) {
                Text("Xcode 16").tag("Xcode 16")
                Text("Xcode 26").tag("Xcode 26")
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 200)

            Spacer()
        }
    }
    .padding()
}
