import SwiftUI
import MagicCore

/**
 经典Banner布局视图
 专门为经典模板设计的布局组件，包含缩放和手势支持
 */
struct ClassicBannerLayout: View {
    @EnvironmentObject var b: BannerProvider
    
    @State private var visible = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                content
                    .frame(width: b.selectedDevice.width, height: b.selectedDevice.height)
                    .scaleEffect(calculateOptimalScale(geometry: geo))
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        .padding()
    }
    
    private var content: some View {
        ZStack {
            switch b.selectedDevice {
            case .iMac, .MacBook:
                HStack(spacing: 0) {
                    VStack(spacing: 0, content: {
                        Spacer()
                        VStack(spacing: 50) {
                            ClassicTitle()
                            ClassicSubTitle()
                        }
                        .frame(height: b.selectedDevice.height / 3)
                        ClassicFeatures()
                        Spacer()
                    })
                    .frame(width: b.selectedDevice.width / 3)

                    ClassicImage()
                        .padding(.horizontal, 50)
                        .frame(width: b.selectedDevice.width / 3 * 2)
                        .frame(maxHeight: .infinity)
                }
            case .iPhoneSmall, .iPhoneBig:
                VStack(spacing: 40) {
                    Spacer()
                    ClassicTitle()
                    ClassicSubTitle()
                    Spacer()
                    ClassicImage()
                        .frame(maxHeight: .infinity)
                }.padding()
            case .iPad:
                GeometryReader { _ in
                    ClassicTitle()
                    ClassicSubTitle()
                    Spacer()
                    ClassicImage()
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
        let widthScale = availableWidth / b.selectedDevice.width
        let heightScale = availableHeight / b.selectedDevice.height

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
    .frame(height: 800)
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
