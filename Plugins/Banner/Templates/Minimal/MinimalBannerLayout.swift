import SwiftUI
import MagicCore

/**
 简约Banner布局视图
 居中简洁的布局设计
 */
struct MinimalBannerLayout: View {
    @EnvironmentObject var b: BannerProvider
    let device: Device
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            content
                .frame(width: geo.size.width)
                .frame(height: geo.size.height)
                .alignmentGuide(HorizontalAlignment.center) { _ in geo.size.width / 2 }
                .alignmentGuide(VerticalAlignment.center) { _ in geo.size.height / 2 }
                .scaleEffect(calculateOptimalScale(geometry: geo) * scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
        }
        .padding()
    }
    
    private var content: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 居中的标题和副标题
            VStack(spacing: 20) {
                BannerTitle()
                BannerSubTitle()
            }
            
            Spacer()
            
            // 居中的图片
            BannerImage(device: device)
                .frame(width: min(device.width * 0.3, 300))
                .frame(height: min(device.height * 0.3, 200))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BannerBackground())
    }
    
    /// 计算最优缩放比例
    private func calculateOptimalScale(geometry: GeometryProxy) -> CGFloat {
        let availableWidth = geometry.size.width
        let availableHeight = geometry.size.height
        let widthScale = availableWidth / device.width
        let heightScale = availableHeight / device.height
        return min(widthScale, heightScale)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
