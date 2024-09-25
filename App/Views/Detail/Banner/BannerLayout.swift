import SwiftUI
import MagicKit

struct BannerLayout: View {
    @Binding var banner: BannerModel

    var device: Device { banner.getDevice() }

    var body: some View {
        ZStack {
            switch Device(rawValue: banner.device) {
            case .iMac, .MacBook:
                HStack(spacing: 20) {
                    VStack(spacing: 0, content: {
                        VStack {
                            BannerTitle(banner: $banner)
                            BannerSubTitle(banner: $banner)
                        }.frame(height: device.height / 3)
                        Features(features: $banner.features)
                        Spacer()
                    })
                    .background(.red.opacity(0.0)).frame(width: device.width / 3)

                    BannerImage(banner: $banner)
                        .padding(.trailing, 100)
                        .frame(width: device.width / 3 * 2)
                        .background(.green.opacity(0.0))
                }
            case .iPhoneSmall, .iPhoneBig:
                VStack(spacing: 40, content: {
                    BannerTitle(banner: $banner)
                    BannerSubTitle(banner: $banner).padding()
                    Spacer()
                    BannerImage(banner: $banner)
                        .frame(maxHeight: .infinity)
                })
            case .iPad, .none:
                GeometryReader { _ in
                    BannerTitle(banner: $banner)
                    BannerSubTitle(banner: $banner)
                    Spacer()
                    BannerImage(banner: $banner)
                }
            }
        }
        .background(BackgroundGroup(for:banner.backgroundId).opacity(banner.opacity))
    }
}

#Preview("App") {
    RootView {
        Content()
    }
    .frame(height: 800)
    .frame(width: 800)
}

#Preview("App-2") {
    RootView {
        Content()
    }
    .frame(height: 1200)
    .frame(width: 800)
}
