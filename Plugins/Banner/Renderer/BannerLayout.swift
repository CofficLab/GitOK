import MagicCore
import SwiftUI

/**
    Banner布局渲染器
    纯显示组件，只负责根据不同设备类型渲染Banner布局。
    不包含任何编辑功能，数据变化时自动重新渲染。
    
    ## 功能特性
    - 支持多种设备类型布局
    - 纯显示，无编辑功能
    - 响应数据变化自动重新渲染
    - 清晰的布局结构
**/
struct BannerLayout: View {
    @EnvironmentObject var b: BannerProvider
    let device: Device
    
    var body: some View {
        ZStack {
            switch device {
            case .iMac, .MacBook:
                HStack(spacing: 0) {
                    VStack(spacing: 0, content: {
                        Spacer()
                        VStack(spacing: 50) {
                            BannerTitle()
                            BannerSubTitle()
                        }
                        .frame(height: device.height / 3)
                        Features()
                        Spacer()
                    })
                    .frame(width: device.width / 3)
                    
                    BannerImage(device: device)
                        .padding(.horizontal, 50)
                        .frame(width: device.width / 3 * 2)
                        .frame(maxHeight: .infinity)
                }
            case .iPhoneSmall, .iPhoneBig:
                VStack(spacing: 40, content: {
                    BannerTitle()
                    BannerSubTitle()
                    Spacer()
                    BannerImage(device: device)
                        .frame(maxHeight: .infinity)
                })
            case .iPad:
                GeometryReader { _ in
                    BannerTitle()
                    BannerSubTitle()
                    Spacer()
                    BannerImage(device: device)
                }
            }
        }
        .background(BannerBackground())
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideTabPicker()
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
