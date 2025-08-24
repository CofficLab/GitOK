import MagicCore
import SwiftUI

/**
 * 图标预览组件
 * 显示单个图标预览，自动适应当前可用空间
 * 使用IconRenderer来渲染图标样式
 */
struct IconPreview: View {
    let iconData: IconData
    let iconAsset: IconAsset
    
    var body: some View {
        VStack(spacing: 16) {
            Text("图标预览")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 自适应图标预览
            GeometryReader { geometry in
                let availableSize = min(geometry.size.width, geometry.size.height) * 0.8
                
                IconRenderer.renderIcon(iconData: iconData, iconAsset: iconAsset)
                    .frame(width: availableSize, height: availableSize)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
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
