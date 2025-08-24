import SwiftUI
import MagicCore

/**
 * 图标渲染器
 * 根据IconData和IconAsset来渲染最终的图标样式
 * 不关心图标是本地还是远程，只负责组合背景和图标
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
    
    /// 渲染静态图标（用于截图）
    /// - Parameters:
    ///   - iconData: 图标数据
    ///   - iconAsset: 图标资源
    ///   - size: 图标尺寸
    /// - Returns: 完全静态的图标视图，适合截图
    static func renderStaticIcon(iconData: IconData, iconAsset: IconAsset, size: CGFloat) -> some View {
        ZStack {
            // 背景
            renderBackground(iconData: iconData)
                .frame(width: size, height: size)
            
            // 图标内容 - 确保完全静态
            if iconAsset.source == .local {
                // 本地图标：直接使用静态图片
                iconAsset.getImage()
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(iconData.scale ?? 1.0)
                    .frame(width: size * 0.6, height: size * 0.6)
            } else {
                // 远程图标：使用静态占位符，避免异步加载问题
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .scaleEffect(iconData.scale ?? 1.0)
                    .frame(width: size * 0.6, height: size * 0.6)
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(iconData.cornerRadius > 0 ? CGFloat(iconData.cornerRadius) : 0)
        .opacity(iconData.opacity)
        .clipped()
    }
    
    /// 生成图标截图
    /// - Parameters:
    ///   - iconData: 图标数据
    ///   - iconAsset: 图标资源
    ///   - size: 图标尺寸
    ///   - savePath: 保存路径
    /// - Returns: 截图是否成功
    @MainActor static func snapshotIcon(iconData: IconData, iconAsset: IconAsset, size: Int, savePath: URL) -> Bool {
        let _ = MagicImage.snapshot(
            MagicImage.makeImage(
                renderStaticIcon(iconData: iconData, iconAsset: iconAsset, size: CGFloat(size))
            )
            .resizable()
            .scaledToFit()
            .frame(width: CGFloat(size), height: CGFloat(size)),
            path: savePath
        )
        
        // 返回文件是否成功生成
        return FileManager.default.fileExists(atPath: savePath.path)
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
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.secondary)
                    @unknown default:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // 使用IconAsset的视图（自动处理本地和远程）
                iconAsset.getIconView()
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
