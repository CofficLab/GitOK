import MagicCore
import OSLog
import SwiftUI

/**
 * Banner图片纯显示组件
 * 只负责显示图片，不包含任何编辑功能
 * 数据变化时自动重新渲染
 */
struct BannerImage: View {
    @EnvironmentObject var b: BannerProvider
    let device: Device

    var image: Image { b.banner.getImage() }

    var body: some View {
        ZStack {
            if b.banner.inScreen {
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
                image.resizable()
                    .scaledToFit()
            }
        }
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
    .frame(width: 1200)
    .frame(height: 1200)
}
