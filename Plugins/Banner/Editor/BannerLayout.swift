import MagicKit
import SwiftUI

struct BannerLayout: View {
    @Binding var banner: BannerModel
    @Binding var showBorder: Bool

    var device: Device { banner.getDevice() }

    var body: some View {
        ZStack {
            switch Device(rawValue: banner.device) {
            case .iMac, .MacBook:
                HStack(spacing: 0) {
                    VStack(spacing: 0, content: {
                        Spacer()
                        VStack(spacing: 50) {
                            BannerTitle(banner: $banner)
                            BannerSubTitle(banner: $banner)
                        }
                        .frame(height: device.height / 3)
                        Features(features: $banner.features)
                        Spacer()
                    })
                    .frame(width: device.width / 3)
                    .overlay(
                        showBorder ? Rectangle()
                            .strokeBorder(style: StrokeStyle(lineWidth: 20, dash: [5]))
                            .foregroundColor(.red) : nil
                    )

                    BannerImage(banner: $banner)
                        .padding(.horizontal, 50)
                        .frame(width: device.width / 3 * 2)
                        .frame(maxHeight: .infinity)
                        .overlay(
                            showBorder ? Rectangle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 20, dash: [5]))
                                .foregroundColor(.yellow) : nil
                        )
                }
            case .iPhoneSmall, .iPhoneBig:
                VStack(spacing: 40, content: {
                    BannerTitle(banner: $banner)
                    BannerSubTitle(banner: $banner).padding()
                    Spacer()
                    BannerImage(banner: $banner)
                        .frame(maxHeight: .infinity)
                        .overlay(
                            showBorder ? Rectangle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(.black) : nil
                        )
                })
            case .iPad, .none:
                GeometryReader { _ in
                    BannerTitle(banner: $banner)
                    BannerSubTitle(banner: $banner)
                    Spacer()
                    BannerImage(banner: $banner)
                        .overlay(
                            showBorder ? Rectangle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(.black) : nil
                        )
                }
            }
        }
        .background(BannerBackground(banner: $banner))
    }
}

#Preview("BannerHome") {
    struct PreviewWrapper: View {
        @State var previewBanner = BannerModel(
            title: "制作海报",
            subTitle: "简单又快捷",
            features: [
                "无广告",
                "好软件",
                "无弹窗",
                "无会员",
            ],
            path: ""
        )

        var body: some View {
            RootView {
                BannerEditor(banner: $previewBanner)
            }
            .frame(width: 500)
            .frame(height: 500)
        }
    }

    return PreviewWrapper()
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
