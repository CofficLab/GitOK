import MagicCore
import SwiftUI

/**
 * 图标预览组件
 * 显示单个图标预览，自动适应当前可用空间
 */
struct IconPreview: View {
    let icon: IconModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("图标预览")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 自适应图标预览
            GeometryReader { geometry in
                let availableSize = min(geometry.size.width, geometry.size.height) * 0.8
                
                ZStack {
                    // 背景
                    icon.background
                        .frame(width: availableSize, height: availableSize)
                        .cornerRadius(availableSize * 0.2)
                    
                    // 图标
                    icon.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: availableSize * 0.8, height: availableSize * 0.8)
                }
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
