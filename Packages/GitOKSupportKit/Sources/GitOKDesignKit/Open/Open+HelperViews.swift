import GitOKFoundationKit
import SwiftUI

// MARK: - Helper Views

#if os(macOS)
/// 真实应用图标视图
/// 处理 NSImage 到 SwiftUI Image 的转换
struct RealIconButtonView: View {
    let appType: OpenAppType
    let url: URL

    var body: some View {
        let iconValue = appType.realIcon(for: url, useRealIcon: true)

        if let nsImage = iconValue as? NSImage {
            // 使用真实应用图标
            // 注意：需要 .resizable() 才能让 NSImage 适应 frame 的大小
            Image(nsImage: nsImage)
                .resizable()
        } else if let iconName = iconValue as? String {
            // 回退到系统图标
            // SF Symbols 不需要 .resizable()，它们会自动缩放
            Image(systemName: iconName)
        } else {
            // 默认图标
            Image(systemName: "app")
        }
    }
}
#else
/// iOS 版本（不支持真实图标）
struct RealIconButtonView: View {
    let appType: OpenAppType
    let url: URL

    var body: some View {
        Image(systemName: appType.icon(for: url))
    }
}
#endif

#if macOS
// MARK: - Previews

#endif

