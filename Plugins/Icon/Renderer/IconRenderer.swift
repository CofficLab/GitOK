import MagicCore
import MagicBackground
import SwiftUI

/**
 * 图标渲染器
 * 主要用于生成图标截图，支持本地和远程图标
 * 现在主要用于导出和保存功能，预览使用响应式视图
 */
class IconRenderer {
    /// 生成图标截图
    /// - Parameters:
    ///   - iconData: 图标数据
    ///   - iconAsset: 图标资源
    ///   - size: 图标尺寸
    ///   - savePath: 保存路径
    /// - Returns: 截图是否成功
    @MainActor static func snapshotIcon(iconData: IconData, iconAsset: IconAsset, size: Int, savePath: URL) async -> Bool {
        // 先异步获取图标图片
        let iconImage = await iconAsset.getImage()
        
        // 创建图标视图
        let iconView = createIconView(iconData: iconData, iconAsset: iconAsset, size: CGFloat(size), preloadedImage: iconImage)
        
        let _ = iconView.snapshot(path: savePath)

        // 返回文件是否成功生成
        return FileManager.default.fileExists(atPath: savePath.path)
    }

    // MARK: - 私有方法

    /// 创建图标视图（用于截图）
    /// - Parameters:
    ///   - iconData: 图标数据
    ///   - iconAsset: 图标资源
    ///   - size: 图标尺寸
    ///   - preloadedImage: 预加载的图片（可选）
    /// - Returns: 图标视图
    private static func createIconView(iconData: IconData, iconAsset: IconAsset, size: CGFloat, preloadedImage: Image? = nil) -> some View {
        // 计算实际内容尺寸（考虑padding）
        let contentSize = size * (1.0 - iconData.padding * 2)
        
        return ZStack {
            // 背景
            MagicBackgroundGroup(for: iconData.backgroundId)
                .opacity(iconData.opacity)
            
            // 图标内容
            if let imageURL = iconData.imageURL {
                // 使用自定义图片URL
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(iconData.scale ?? 1.0)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.secondary)
                            .scaleEffect(iconData.scale ?? 1.0)
                    @unknown default:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.secondary)
                            .scaleEffect(iconData.scale ?? 1.0)
                    }
                }
            } else if let preloadedImage = preloadedImage {
                // 使用预加载的图片
                preloadedImage
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(iconData.scale ?? 1.0)
            } else {
                // 使用占位符图片，因为这里主要用于截图，应该总是有预加载的图片
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
                    .scaleEffect(iconData.scale ?? 1.0)
            }
        }
        // 将圆角按尺寸比例缩放：以 1024 为基准，保证不同导出尺寸视觉一致
        .cornerRadius({
            let base: CGFloat = 1024
            let scaled = CGFloat(iconData.cornerRadius) * (contentSize / base)
            return iconData.cornerRadius > 0 ? max(0, scaled) : 0
        }())
        .frame(width: contentSize, height: contentSize)
        .frame(width: size, height: size)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
