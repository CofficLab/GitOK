import MagicCore
import MagicAll
import MagicAlert
import SwiftUI

/**
 经典模板的图片组件
 专门为经典布局设计的图片显示组件
 */
struct ClassicImage: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider

    var banner: BannerFile { b.banner }
    var classicData: ClassicBannerData? { banner.classicData }
    var image: Image { classicData?.getImage(banner.project.url) ?? Image(ClassicBannerData.defaultImageId) }

    var body: some View {
        ZStack {
            if let device = classicData?.selectedDevice {
                switch device {
                case .iMac:
                    iMacScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .MacBook:
                    MacBookScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPhoneBig:
                    iPhoneScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPhoneSmall:
                    iPhoneScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPad_mini:
                    iPadScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPhone_15:
                    iPhoneScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPhone_SE:
                    iPhoneScreen(content: {
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
