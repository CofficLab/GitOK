import SwiftUI
import MagicCore

/**
 经典Banner布局视图
 专门为经典模板设计的布局组件，包含缩放和手势支持
 */
struct ClassicBannerLayout: View {
    @EnvironmentObject var b: BannerProvider
    let device: Device
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var visible = false

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
        ZStack {
            switch device {
            case .iMac, .MacBook:
                HStack(spacing: 0) {
                    VStack(spacing: 0, content: {
                        Spacer()
                        VStack(spacing: 50) {
                            ClassicTitle()
                            ClassicSubTitle()
                        }
                        .frame(height: device.height / 3)
                        ClassicFeatures()
                        Spacer()
                    })
                    .frame(width: device.width / 3)

                    ClassicImage(device: device)
                        .padding(.horizontal, 50)
                        .frame(width: device.width / 3 * 2)
                        .frame(maxHeight: .infinity)
                }
            case .iPhoneSmall, .iPhoneBig:
                VStack(spacing: 40, content: {
                    ClassicTitle()
                    ClassicSubTitle()
                    Spacer()
                    ClassicImage(device: device)
                        .frame(maxHeight: .infinity)
                })
            case .iPad:
                GeometryReader { _ in
                    ClassicTitle()
                    ClassicSubTitle()
                    Spacer()
                    ClassicImage(device: device)
                }
            }
        }
        .background(ClassicBackground())
    }
    
    /// 计算最优缩放比例
    /// 根据当前设备和容器大小计算最佳显示比例
    private func calculateOptimalScale(geometry: GeometryProxy) -> CGFloat {
        // 计算可用空间
        let availableWidth = geometry.size.width
        let availableHeight = geometry.size.height

        // 直接使用当前设备的尺寸进行计算
        let widthScale = availableWidth / device.width
        let heightScale = availableHeight / device.height

        // 选择较小的比例确保完整显示
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
