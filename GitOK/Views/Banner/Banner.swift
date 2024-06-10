import SwiftUI

struct Banner: View {
    var url: URL? = nil
    var iconId: String? = nil
    var backgroundId: String = "1"
    var device: Device
    var title: String = "默认标题"
    var subTitle: String = "小标题"
    var inScreen: Bool = true
    var badges: [String]
    var image: Image

    var body: some View {
        ZStack {
            switch device {
            case .iMac:
                BanneriMac(
                    device: device,
                    title: title,
                    subTitle: subTitle,
                    inScreen: inScreen,
                    badges: badges,
                    image: image
                )
            case .MacBook:
                BannerMacBook(
                    device: device,
                    title: title,
                    subTitle: subTitle,
                    inScreen: inScreen,
                    badges: badges,
                    image: image
                )
            case .iPhoneSmall, .iPhoneBig:
                BanneriPhone(
                    device: device,
                    title: title,
                    subTitle: subTitle,
                    inScreen: inScreen,
                    badges: badges,
                    image: image
                )
            case .iPad:
                BanneriPad(
                    device: device,
                    title: title,
                    subTitle: subTitle,
                    inScreen: inScreen,
                    badges: badges,
                    image: image
                )
            }
        }
    }
}

#Preview("Banner") {
    RootView {
        Banner(
            device: .iPhoneBig,
            badges: [
                "特性1",
                "特性2",
            ],
            image: Image("AppIcon")
        )
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App") {
    RootView {
        Content()
    }
}
