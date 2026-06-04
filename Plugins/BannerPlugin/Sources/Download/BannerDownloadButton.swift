import GitOKCoreKit
import SwiftUI


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
        AppButton(title, systemImage: icon, style: .tonal, fillsWidth: true, action: action)
        .disabled(isDisabled)
    }
}
