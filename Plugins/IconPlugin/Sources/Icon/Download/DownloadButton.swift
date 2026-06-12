
import SwiftUI
import GitOKCoreKit
import GitOKUI

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
        if let customContent {
            AppActionCard(title, systemImage: icon, tint: color, isDisabled: isDisabled, action: action) {
                customContent()
            }
        } else {
            AppActionCard(title, systemImage: icon, tint: color, isDisabled: isDisabled, action: action)
        }
    }
}
