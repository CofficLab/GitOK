import MagicCore
import SwiftUI

/**
 * 图标预览组件
 * 显示单个图标预览，自动适应当前可用空间
 * 使用IconRenderer来渲染图标样式
 * 自动从IconProvider环境变量中获取图标数据
 */
struct IconPreview: View {
    let iconData: IconData
    
    @EnvironmentObject var iconProvider: IconProvider
    @State private var iconAsset: IconAsset?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("图标预览")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 自适应图标预览
            GeometryReader { geometry in
                let availableSize = min(geometry.size.width, geometry.size.height) * 0.8
                
                if let iconAsset = iconAsset {
                    IconRenderer.renderIcon(iconData: iconData, iconAsset: iconAsset)
                        .frame(width: availableSize, height: availableSize)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 显示加载状态
                    ProgressView()
                        .frame(width: availableSize, height: availableSize)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            loadIconAsset()
        }
        .onChange(of: iconData.iconId) { _, _ in
            loadIconAsset()
        }
    }
    
    /// 根据iconData.iconId加载对应的IconAsset
    private func loadIconAsset() {
        Task {
            if let iconAsset = await IconRepo.shared.getIconAsset(byId: iconData.iconId) {
                await MainActor.run {
                    self.iconAsset = iconAsset
                }
            }
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
