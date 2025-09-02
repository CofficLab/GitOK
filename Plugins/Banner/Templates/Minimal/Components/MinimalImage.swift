import MagicCore
import SwiftUI

/**
 简约模板的图片组件
 专门为简约布局设计的图片显示组件
 */
struct MinimalImage: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider

    var banner: BannerFile { b.banner }
    var image: Image { banner.getImage() }
    var device: Device { b.selectedDevice }

    var body: some View {
        ZStack {
            if banner.inScreen {
                switch device {
                case .iMac:
                    ScreeniMac(content: {
                        image.resizable().scaledToFit()
                    })
                case .MacBook:
                    ScreenMacBook(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPhoneBig:
                    ScreeniPhone(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPhoneSmall:
                    ScreeniPhone(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPad:
                    ScreeniPad(content: {
                        image.resizable().scaledToFit()
                    })
                }
            } else {
                image
                    .resizable()
                    .scaledToFit()
            }
        }
    }

    private func getCornerRadius() -> CGFloat {
        // 简约模板使用较大的圆角
        return 16.0
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 600)
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
