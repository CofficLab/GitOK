import SwiftUI

struct BannerDevice: View {
    var banner: BannerModel
    var image: Image

    var body: some View {
        ZStack {
            switch Device.init(rawValue: banner.device) {
            case .iMac:
                BanneriMac(
                    device: Device(rawValue: banner.device)!,
                    title: banner.title,
                    subTitle: banner.subTitle,
                    inScreen: banner.inScreen,
                    badges: banner.features,
                    image: image
                )
            case .MacBook:
                BannerMacBook(
                    device: Device(rawValue: banner.device)!,
                    title: banner.title,
                    subTitle: banner.subTitle,
                    inScreen: banner.inScreen,
                    badges: banner.features,
                    image: image
                )
            case .iPhoneSmall, .iPhoneBig:
                BanneriPhone(
                    device: Device(rawValue: banner.device)!,
                    title: banner.title,
                    subTitle: banner.subTitle,
                    inScreen: banner.inScreen,
                    badges: banner.features,
                    image: image
                )
            case .iPad,.none:
                BanneriPad(
                    device: Device(rawValue: banner.device)!,
                    title: banner.title,
                    subTitle: banner.subTitle,
                    inScreen: banner.inScreen,
                    badges: banner.features,
                    image: image
                )
            }
        }
    }
}

#Preview("App") {
    RootView {
        Content()
    }
}
