import MagicCore
import SwiftUI

/**
 * 图标预览组件
 * 显示单个图标预览，自动适应当前可用空间
 * 使用响应式视图直接绑定数据状态，避免重复渲染
 * 自动从IconProvider环境变量中获取图标数据
 */
struct IconPreview: View {
    @EnvironmentObject var iconProvider: IconProvider
    @State private var iconAsset: IconAsset?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        GeometryReader { geometry in
            let containerHeight = geometry.size.height
            let containerWidth = geometry.size.width
            let constrainedSize = min(containerHeight, containerWidth)
            let centerX = containerWidth / 2
            let centerY = containerHeight / 2

            Group {
                if let iconAsset = iconAsset, let iconData = iconProvider.currentData {
                    // 响应式图标视图，直接绑定数据状态
                    ResponsiveIconView(
                        iconData: iconData,
                        iconAsset: iconAsset,
                        size: constrainedSize
                    )
                } else if isLoading {
                    IconStateView(
                        icon: nil,
                        title: "加载图标中...",
                        subtitle: nil,
                        color: .secondary,
                        size: constrainedSize,
                        showProgress: true
                    )
                } else if let errorMessage = errorMessage {
                    IconStateView(
                        icon: "exclamationmark.triangle",
                        title: "加载失败",
                        subtitle: errorMessage,
                        color: .orange,
                        size: constrainedSize,
                        showRetryButton: true,
                        onRetry: loadIconAsset
                    )
                } else {
                    IconStateView(
                        icon: "photo",
                        title: "请选择一个图标",
                        subtitle: nil,
                        color: .secondary,
                        size: constrainedSize
                    )
                }
            }
            .position(x: centerX, y: centerY)
            .frame(width: constrainedSize, height: constrainedSize)
        }
        .onAppear {
            loadIconAsset()
        }
        .onChange(of: iconProvider.selectedIconId) { _, newValue in
            // 当selectedIconId变化时，重新加载图标资源
            if !newValue.isEmpty {
                self.iconAsset = nil
                self.errorMessage = nil
                self.isLoading = true
                loadIconAsset()
            } else {
                // 如果没有选中的图标，清空所有状态
                self.iconAsset = nil
                self.errorMessage = nil
                self.isLoading = false
            }
        }
        .onChange(of: iconProvider.currentData) { _, newValue in
            // 当currentData变化时，重新加载图标资源
            if newValue != nil {
                loadIconAsset()
            }
        }
    }

    private func loadIconAsset() {
        guard !iconProvider.selectedIconId.isEmpty else {
            self.iconAsset = nil
            self.errorMessage = nil
            self.isLoading = false
            return
        }

        Task {
            let iconAsset = await IconRepo.shared.getIconAsset(byId: iconProvider.selectedIconId)

            await MainActor.run {
                if let iconAsset = iconAsset {
                    self.iconAsset = iconAsset
                    self.errorMessage = nil
                    self.isLoading = false
                } else {
                    self.iconAsset = nil
                    self.errorMessage = "未找到图标：\(iconProvider.selectedIconId)"
                    self.isLoading = false
                }
            }
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
            // 背景 - 直接绑定backgroundId和opacity
            MagicBackgroundGroup(for: iconData.backgroundId)
                .opacity(iconData.opacity)
            
            // 图标内容 - 直接绑定所有相关属性
            ResponsiveIconContent(
                iconData: iconData,
                iconAsset: iconAsset
            )
        }
        .frame(width: size, height: size)
        .cornerRadius(iconData.cornerRadius > 0 ? CGFloat(iconData.cornerRadius) : 0)
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
            let image = await iconAsset.getImageAsync()
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
    .frame(width: 1200)
    .frame(height: 1200)
}
