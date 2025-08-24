import MagicCore
import SwiftUI

/**
 * 图标预览组件
 * 显示单个图标预览，自动适应当前可用空间
 * 使用IconRenderer来渲染图标样式
 * 自动从IconProvider环境变量中获取图标数据
 */
struct IconPreview: View {
    @EnvironmentObject var iconProvider: IconProvider
    @State private var iconAsset: IconAsset?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        GeometryReader { geometry in
            let availableSize = min(geometry.size.width, geometry.size.height)

            if let iconAsset = iconAsset, !isLoading && errorMessage == nil {
                // 从IconProvider获取当前图标数据
                if let iconData = iconProvider.currentData {
                    // 使用异步渲染方法，传递合适的尺寸
                    AsyncIconRenderer(iconData: iconData, iconAsset: iconAsset, size: availableSize)
                        .frame(width: availableSize, height: availableSize)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                } else {
                    // 没有图标数据时显示提示
                    IconStateView(
                        icon: "photo",
                        title: "请选择一个图标",
                        subtitle: nil,
                        color: .secondary,
                        size: availableSize
                    )
                }
            } else if isLoading {
                // 显示加载状态
                IconStateView(
                    icon: nil,
                    title: "加载图标中...",
                    subtitle: nil,
                    color: .secondary,
                    size: availableSize,
                    showProgress: true
                )
            } else if let errorMessage = errorMessage {
                // 显示错误状态
                IconStateView(
                    icon: "exclamationmark.triangle",
                    title: "加载失败",
                    subtitle: errorMessage,
                    color: .orange,
                    size: availableSize,
                    showRetryButton: true,
                    onRetry: loadIconAsset
                )
            } else {
                // 显示空状态
                IconStateView(
                    icon: "photo",
                    title: "请选择一个图标",
                    subtitle: nil,
                    color: .secondary,
                    size: availableSize
                )
            }
        }
        .onAppear {
            loadIconAsset()
        }
        .onChange(of: iconProvider.selectedIconId) { _, newValue in
            // 当selectedIconId变化时，立即清空当前图标并重新加载
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

// MARK: - 异步图标渲染器组件

/**
 * 异步图标渲染器组件
 * 使用IconRenderer.renderStaticIconAsync方法渲染图标
 */
struct AsyncIconRenderer: View {
    let iconData: IconData
    let iconAsset: IconAsset
    let size: CGFloat
    
    @State private var renderedView: AnyView?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let renderedView = renderedView {
                renderedView
            } else if isLoading {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            renderIcon()
        }
        .onChange(of: iconData.opacity) { _, _ in
            // 当透明度变化时重新渲染
            renderIcon()
        }
        .onChange(of: iconData.scale) { _, _ in
            // 当缩放比例变化时重新渲染
            renderIcon()
        }
        .onChange(of: iconData.cornerRadius) { _, _ in
            // 当圆角半径变化时重新渲染
            renderIcon()
        }
        .onChange(of: iconData.backgroundId) { _, _ in
            // 当背景样式变化时重新渲染
            renderIcon()
        }
        .onChange(of: iconData.imageURL) { _, _ in
            // 当自定义图片URL变化时重新渲染
            renderIcon()
        }
    }
    
    @MainActor
    private func renderIcon() {
        isLoading = true
        
        Task {
            let view = await IconRenderer.renderStaticIconAsync(
                iconData: iconData,
                iconAsset: iconAsset,
                size: size
            )
            
            self.renderedView = AnyView(view)
            self.isLoading = false
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
