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
    @State private var renderedView: AnyView?
    @State private var isRendering: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let containerHeight = geometry.size.height
            let containerWidth = geometry.size.width
            let constrainedSize = min(containerHeight, containerWidth)
            let centerX = containerWidth / 2
            let centerY = containerHeight / 2

            Group {
                if iconAsset != nil, !isLoading && errorMessage == nil {
                    if iconProvider.currentData != nil {
                        if let renderedView = renderedView, !isRendering {
                            renderedView
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        } else {
                            renderLoadingView(size: constrainedSize)
                        }
                    } else {
                        IconStateView(
                            icon: "photo",
                            title: "请选择一个图标",
                            subtitle: nil,
                            color: .secondary,
                            size: constrainedSize
                        )
                    }
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
            // 当selectedIconId变化时，立即清空当前图标并重新加载
            if !newValue.isEmpty {
                self.iconAsset = nil
                self.errorMessage = nil
                self.isLoading = true
                self.renderedView = nil
                loadIconAsset()
            } else {
                // 如果没有选中的图标，清空所有状态
                self.iconAsset = nil
                self.errorMessage = nil
                self.isLoading = false
                self.renderedView = nil
            }
        }
        .onChange(of: iconProvider.currentData) { _, newValue in
            // 当currentData变化时，重新加载图标资源
            if newValue != nil {
                loadIconAsset()
            }
        }
        .onChange(of: iconProvider.currentData?.opacity) { _, _ in
            // 当透明度变化时重新渲染
            if let iconData = iconProvider.currentData, let iconAsset = iconAsset {
                renderIcon(iconData: iconData, iconAsset: iconAsset, size: 300) // 使用约束后的尺寸
            }
        }
        .onChange(of: iconProvider.currentData?.scale) { _, _ in
            // 当缩放比例变化时重新渲染
            if let iconData = iconProvider.currentData, let iconAsset = iconAsset {
                renderIcon(iconData: iconData, iconAsset: iconAsset, size: 300) // 使用约束后的尺寸
            }
        }
        .onChange(of: iconProvider.currentData?.cornerRadius) { _, _ in
            // 当圆角半径变化时重新渲染
            if let iconData = iconProvider.currentData, let iconAsset = iconAsset {
                renderIcon(iconData: iconData, iconAsset: iconAsset, size: 300) // 使用约束后的尺寸
            }
        }
        .onChange(of: iconProvider.currentData?.backgroundId) { _, _ in
            // 当背景样式变化时重新渲染
            if let iconData = iconProvider.currentData, let iconAsset = iconAsset {
                renderIcon(iconData: iconData, iconAsset: iconAsset, size: 300) // 使用约束后的尺寸
            }
        }
        .onChange(of: iconProvider.currentData?.imageURL) { _, _ in
            // 当自定义图片URL变化时重新渲染
            if let iconData = iconProvider.currentData, let iconAsset = iconAsset {
                renderIcon(iconData: iconData, iconAsset: iconAsset, size: 300) // 使用约束后的尺寸
            }
        }
    }

    private func loadIconAsset() {
        guard !iconProvider.selectedIconId.isEmpty else {
            self.iconAsset = nil
            self.errorMessage = nil
            self.isLoading = false
            self.renderedView = nil
            return
        }

        Task {
            let iconAsset = await IconRepo.shared.getIconAsset(byId: iconProvider.selectedIconId)

            await MainActor.run {
                if let iconAsset = iconAsset {
                    self.iconAsset = iconAsset
                    self.errorMessage = nil
                    self.isLoading = false
                    // 加载完图标资源后，开始渲染
                    renderIcon(iconData: iconProvider.currentData, iconAsset: iconAsset, size: 300) // 使用约束后的尺寸
                } else {
                    self.iconAsset = nil
                    self.errorMessage = "未找到图标：\(iconProvider.selectedIconId)"
                    self.isLoading = false
                    self.renderedView = nil
                }
            }
        }
    }

    @MainActor
    private func renderIcon(iconData: IconData?, iconAsset: IconAsset, size: CGFloat) {
        guard let iconData = iconData else { return }

        isRendering = true

        Task {
            let view = await IconRenderer.renderStaticIconAsync(
                iconData: iconData,
                iconAsset: iconAsset,
                size: size
            )

            self.renderedView = AnyView(view)
            self.isRendering = false
        }
    }

    // 提取渲染加载视图为单独的方法
    private func renderLoadingView(size: CGFloat) -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .frame(width: 50, height: 50)
            Text("渲染图标中...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
    .frame(width: 1200)
    .frame(height: 1200)
}
