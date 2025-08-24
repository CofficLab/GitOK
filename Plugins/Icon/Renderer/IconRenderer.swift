import MagicCore
import SwiftUI

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
    
    /// 异步渲染静态图标（支持远程图标预加载）
    /// - Parameters:
    ///   - iconData: 图标数据
    ///   - iconAsset: 图标资源
    ///   - size: 图标尺寸
    /// - Returns: 完全静态的图标视图，适合截图
    @MainActor
    static func renderStaticIconAsync(iconData: IconData, iconAsset: IconAsset, size: CGFloat) async -> some View {
        // 先异步获取图标图片
        let iconImage = await iconAsset.getImageAsync()
        
        // 然后构建静态视图
        return ZStack {
            // 背景
            renderBackground(iconData: iconData)
                .frame(width: size, height: size)
            
            // 图标内容 - 使用已获取的图片
            iconImage
                .resizable()
                .scaledToFit()
                .scaleEffect(iconData.scale ?? 1.0)
                .frame(width: size * 0.6, height: size * 0.6)
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
    @MainActor static func snapshotIcon(iconData: IconData, iconAsset: IconAsset, size: Int, savePath: URL) async -> Bool {
        let _ = await MagicImage.snapshot(
            MagicImage.makeImage(
                renderStaticIconAsync(iconData: iconData, iconAsset: iconAsset, size: CGFloat(size))
            )
            .resizable()
            .scaledToFit()
            .frame(width: CGFloat(size), height: CGFloat(size)),
            path: savePath
        )
        
        // 返回文件是否成功生成
        return FileManager.default.fileExists(atPath: savePath.path)
    }
    
    /// 异步生成图标截图（支持远程图标预加载）
    /// - Parameters:
    ///   - iconData: 图标数据
    ///   - iconAsset: 图标资源
    ///   - size: 图标尺寸
    ///   - savePath: 保存路径
    /// - Returns: 截图是否成功
    @MainActor static func snapshotIconAsync(iconData: IconData, iconAsset: IconAsset, size: Int, savePath: URL) async -> Bool {
        // 先异步渲染图标视图
        let iconView = await renderStaticIconAsync(iconData: iconData, iconAsset: iconAsset, size: CGFloat(size))
        
        let _ = MagicImage.snapshot(
            MagicImage.makeImage(iconView)
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
                    case let .success(image):
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
                // 使用异步方法获取图标图片
                AsyncIconImage(iconAsset: iconAsset)
            }
        }
    }
    
    /// 异步图标图片组件
    private struct AsyncIconImage: View {
        let iconAsset: IconAsset
        @State private var loadedImage: Image?
        @State private var isLoading = false
        
        var body: some View {
            Group {
                if let loadedImage = loadedImage {
                    loadedImage
                        .resizable()
                        .scaledToFit()
                } else if isLoading {
                    ProgressView()
                        .frame(width: 50, height: 50)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.secondary)
                }
            }
            .onAppear {
                loadIconImage()
            }
        }
        
        @MainActor
        private func loadIconImage() {
            isLoading = true
            Task {
                let image = await iconAsset.getImageAsync()
                loadedImage = image
                isLoading = false
            }
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
