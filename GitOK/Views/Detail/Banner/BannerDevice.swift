import SwiftUI

struct BannerDevice: View {
    @Binding var banner: BannerModel

    var body: some View {
        ZStack {
            switch Device.init(rawValue: banner.device) {
            case .iMac,.MacBook:
                BannerDesktop(banner: $banner)
            case .iPhoneSmall, .iPhoneBig:
                BanneriPhone(banner: $banner)
            case .iPad,.none:
                BanneriPad(
                    device: Device(rawValue: banner.device)!,
                    title: banner.title,
                    subTitle: banner.subTitle,
                    inScreen: banner.inScreen,
                    badges: banner.features,
                    image: banner.getImage()
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
