import MagicCore
import MagicScreen
import SwiftUI

/**
 经典模板的图片组件
 专门为经典布局设计的图片显示组件
 */
struct ClassicImage: View {
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
        // 经典模板使用适中的圆角
        return 12.0
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
