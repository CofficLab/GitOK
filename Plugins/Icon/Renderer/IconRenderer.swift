import SwiftUI
import MagicCore

/**
 * 图标渲染器
 * 根据IconData和IconAsset来渲染最终的图标样式
 */
class IconRenderer {
    /// 渲染图标
    /// - Parameters:
    ///   - iconData: 图标数据
    ///   - iconAsset: 图标资源
    /// - Returns: 渲染后的图标视图
    static func renderIcon(iconData: IconData, iconAsset: IconAsset) -> some View {
        ZStack {
            // 背景
            renderBackground(iconData: iconData)
            
            // 图标
            renderIconImage(iconData: iconData, iconAsset: iconAsset)
        }
        .cornerRadius(iconData.cornerRadius > 0 ? CGFloat(iconData.cornerRadius) : 0)
        .opacity(iconData.opacity)
    }
    
    /// 渲染背景
    /// - Parameter iconData: 图标数据
    /// - Returns: 背景视图
    private static func renderBackground(iconData: IconData) -> some View {
        MagicBackgroundGroup(for: iconData.backgroundId)
    }
    
    /// 渲染图标图片
    /// - Parameters:
    ///   - iconData: 图标数据
    ///   - iconAsset: 图标资源
    /// - Returns: 图标图片视图
    private static func renderIconImage(iconData: IconData, iconAsset: IconAsset) -> some View {
        Group {
            if let imageURL = iconData.imageURL {
                // 使用自定义图片URL
                Image(nsImage: NSImage(data: try! Data(contentsOf: imageURL))!)
                    .resizable()
                    .scaledToFit()
            } else {
                // 使用IconAsset的图片
                iconAsset.getImage()
                    .resizable()
                    .scaledToFit()
            }
        }
        .scaleEffect(iconData.scale ?? 1.0)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
