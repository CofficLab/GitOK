import MagicCore
import SwiftUI

/**
 * 图标预览组件
 * 显示单个图标预览，自动适应当前可用空间
 * 接收明确的数据参数，专注于图标显示逻辑
 */
struct IconPreview: View {
    let iconData: IconData
    let iconAsset: IconAsset

    var body: some View {
        GeometryReader { geometry in
            let containerHeight = geometry.size.height
            let containerWidth = geometry.size.width
            let constrainedSize = min(containerHeight, containerWidth)
            let centerX = containerWidth / 2
            let centerY = containerHeight / 2

            ZStack {
                // 外边框
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    .frame(width: constrainedSize, height: constrainedSize)
                
                // 响应式图标视图，直接使用传入的数据
                ResponsiveIconView(
                    iconData: iconData,
                    iconAsset: iconAsset,
                    size: constrainedSize
                )
            }
            .position(x: centerX, y: centerY)
        }
    }
}

/**
 * 响应式图标视图
 * 直接绑定IconData的状态，自动响应所有属性变化
 * 无需重新渲染，性能更好，响应更快
 */
struct ResponsiveIconView: View {
    let iconData: IconData
    let iconAsset: IconAsset
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // 内边框
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .frame(width: size * (1.0 - iconData.padding * 2), height: size * (1.0 - iconData.padding * 2))
            
            ZStack {
                // 背景 - 直接绑定backgroundId和opacity
                MagicBackgroundGroup(for: iconData.backgroundId)
                    .opacity(iconData.opacity)
                
                // 图标内容 - 直接绑定所有相关属性
                ResponsiveIconContent(
                    iconData: iconData,
                    iconAsset: iconAsset
                )
            }
            .frame(width: size * (1.0 - iconData.padding * 2), height: size * (1.0 - iconData.padding * 2))
            // 将圆角按尺寸比例缩放：以 1024 为基准，保证不同预览尺寸视觉一致
            .cornerRadius({
                let base: CGFloat = 1024
                let scaled = CGFloat(iconData.cornerRadius) * (size / base)
                return iconData.cornerRadius > 0 ? max(0, scaled) : 0
            }())
        }
    }
}

/**
 * 响应式图标内容组件
 * 处理图标的显示逻辑，自动响应数据变化
 */
struct ResponsiveIconContent: View {
    let iconData: IconData
    let iconAsset: IconAsset
    @State private var loadedImage: Image?
    @State private var isLoading = false
    
    var body: some View {
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
            } else {
                // 使用IconAsset的图片
                if let loadedImage = loadedImage {
                    loadedImage
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(iconData.scale ?? 1.0)
                } else if isLoading {
                    ProgressView()
                        .frame(width: 50, height: 50)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.secondary)
                        .scaleEffect(iconData.scale ?? 1.0)
                }
            }
        }
        .onAppear {
            if loadedImage == nil && !isLoading {
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
    .frame(height: 1200)
}
