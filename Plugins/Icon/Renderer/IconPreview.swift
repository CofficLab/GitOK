import MagicCore
import MagicBackground
import SwiftUI

/**
 * 图标预览组件
 * 显示单个图标预览，自动适应当前可用空间
 * 接收明确的数据参数，专注于图标显示逻辑
 */
struct IconPreview: View {
    let iconData: IconData
    let iconAsset: IconAsset
    let applyBackground: Bool
    
    init(iconData: IconData, iconAsset: IconAsset, applyBackground: Bool = false) {
        self.iconData = iconData
        self.iconAsset = iconAsset
        self.applyBackground = applyBackground
    }

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
                
                // 统一的图标渲染视图
                IconRenderView(
                    iconData: iconData,
                    iconAsset: iconAsset,
                    size: constrainedSize,
                    applyBackground: applyBackground,
                    preloadedImage: nil
                )
            }
            .position(x: centerX, y: centerY)
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
