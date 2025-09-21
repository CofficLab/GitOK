import MagicBackground
import MagicCore
import SwiftUI

/**
 * 图标渲染器
 * 主要用于生成图标截图和提供统一的渲染视图
 */
class IconRenderer {
    /// 生成图标截图
    /// - Parameters:
    ///   - iconData: 图标数据
    ///   - iconAsset: 图标资源
    ///   - size: 图标尺寸
    ///   - savePath: 保存路径
    /// - Returns: 截图是否成功
    @MainActor static func snapshot(iconData: IconData, iconAsset: IconAsset, size: Int, savePath: URL) async -> Bool {
        // 先异步获取图标图片
        let iconImage = await iconAsset.getImage()

        let view = IconRenderView(
            iconData: iconData,
            iconAsset: iconAsset,
            size: CGFloat(size),
            applyBackground: true,
            preloadedImage: iconImage
        )
        
        view.snapshot(path: savePath)

        // 返回文件是否成功生成
        return savePath.isFileExist
    }
}

/**
 * 统一的图标渲染视图
 * 可用于预览和最终渲染
 */
struct IconRenderView: View {
    let iconData: IconData
    let iconAsset: IconAsset
    let size: CGFloat
    let applyBackground: Bool
    
    // 允许传入预加载的图片，用于快照
    let preloadedImage: Image?
    
    // 用于异步加载图片（预览时）
    @State private var loadedImage: Image?
    @State private var isLoading = false

    init(iconData: IconData, iconAsset: IconAsset, size: CGFloat, applyBackground: Bool, preloadedImage: Image? = nil) {
        self.iconData = iconData
        self.iconAsset = iconAsset
        self.size = size
        self.applyBackground = applyBackground
        self.preloadedImage = preloadedImage
    }

    public var body: some View {
        let contentSize = size * (1.0 - iconData.padding * 2)

        ZStack {
            // 内边框
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .frame(width: contentSize, height: contentSize)
            
            ZStack {
                // 背景
                if applyBackground {
                    MagicBackgroundGroup(for: iconData.backgroundId)
                        .opacity(iconData.opacity)
                }
                
                // 图标内容
                iconContentView
            }
            .frame(width: contentSize, height: contentSize)
            .cornerRadius({
                let base: CGFloat = 1024
                let scaled = CGFloat(iconData.cornerRadius) * (size / base)
                return iconData.cornerRadius > 0 ? max(0, scaled) : 0
            }())
        }
        .frame(width: size, height: size)
    }
    
    private var iconContentView: some View {
        Group {
            if let imageURL = iconData.imageURL {
                // 自定义图片URL
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
            } else if let image = preloadedImage ?? loadedImage {
                // 使用预加载或已加载的图片
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(iconData.scale ?? 1.0)
            } else if isLoading {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else {
                // 占位符
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
                    .scaleEffect(iconData.scale ?? 1.0)
            }
        }
        .onAppear {
            // 如果没有预加载图片，则异步加载
            if preloadedImage == nil, loadedImage == nil, !isLoading {
                loadIconImage()
            }
        }
    }
    
    @MainActor
    private func loadIconImage() {
        isLoading = true
        Task {
            let image = await iconAsset.getImage()
            loadedImage = image
            isLoading = false
        }
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
