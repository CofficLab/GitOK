import SwiftUI

struct BannerHome: View {
    @EnvironmentObject var app: AppManager

    @Binding var banner: BannerModel
    @State var snapshotTapped: Bool = false

    var body: some View {
        VStack {
            BannerTopBar(snapshotTapped: $snapshotTapped, banner: $banner)

            BannerMaker(
                snapshotTapped: $snapshotTapped,
                onMessage: { message in
                    app.setMessage(message)
                },
                imageURL: banner.imageURL,
                backgroundId: banner.backgroundId,
                device: banner.getDevice(),
                title: banner.title,
                subTitle: banner.subTitle,
                badges: banner.features,
                inScreen: banner.inScreen
            )
        }
    }
}

#Preview("BannerHome") {
    RootView {
        BannerHome(banner: Binding.constant(BannerModel(
            title: "精彩标题",
            subTitle: "精彩小标题",
            features: [
                "无广告",
                "好软件",
                "无弹窗",
                "无会员",
            ],
            path: ""
        )))
    }
    .frame(width: 500)
    .frame(height: 400)
}

#Preview("APP") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
