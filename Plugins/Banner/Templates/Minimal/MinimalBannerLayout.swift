import MagicCore
import SwiftUI

/**
 简约Banner布局视图
 居中简洁的布局设计
 */
struct MinimalBannerLayout: View {
    @EnvironmentObject var b: BannerProvider

    @State private var visible = false

    var body: some View {
        GeometryReader { geo in
            content
                .frame(width: b.selectedDevice.width, height: b.selectedDevice.height)
                .scaleEffect(calculateOptimalScale(geometry: geo))
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }.padding()
    }

    private var content: some View {
        ZStack {
            switch b.selectedDevice {
            case .iMac, .MacBook:
                HStack(spacing: 0) {
                    VStack(spacing: 0, content: {
                        Spacer()
                        VStack(spacing: 50) {
                            MinimalTitle(fontSize: 120)
                        }.frame(height: b.selectedDevice.height / 3)
                        Spacer()
                    })
                    .frame(width: b.selectedDevice.width / 3)

                    MinimalImage()
                        .padding(.horizontal, 50)
                        .frame(width: b.selectedDevice.width / 3 * 2)
                        .frame(maxHeight: .infinity)
                }
            case .iPhoneSmall, .iPhoneBig:
                VStack(spacing: 40) {
                    Spacer()
                    MinimalTitle(fontSize: 120)
                    Spacer()
                    MinimalImage()
                }.padding()
            case .iPad_mini:
                GeometryReader { _ in
                    MinimalTitle(fontSize: 120)
                    Spacer()
                    MinimalImage()
                }
            case .iPhone_15:
                VStack(spacing: 40) {
                    Spacer()
                    MinimalTitle(fontSize: 120)
                    Spacer()
                    MinimalImage()
                }.padding()
            case .iPhone_SE:
                VStack(spacing: 40) {
                    Spacer()
                    MinimalTitle(fontSize: 120)
                    Spacer()
                    MinimalImage()
                }.padding()
            }
        }
        .background(MinimalBackground())
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
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}

