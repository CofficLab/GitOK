import SwiftUI

struct BannerHome: View {
    @EnvironmentObject var app: AppManager

    @Binding var banner: BannerModel?
    @State var snapshotTapped: Bool = false
    @State var backgroundId: String = "3"

    var body: some View {
        GeometryReader { geo in
            if let banner = banner {
                VStack {
                    // MARK: TopBar
                    BannerBar(snapshotTapped: $snapshotTapped, banner: $banner)

                    HStack {
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

                        VStack {
                            Spacer()
                            // MARK: Fields
                            BannerFields(banner: $banner)

                            // MARK: Background
                            GroupBox {
                                Backgrounds(current: $backgroundId)
                            }
                        }
                        .padding(.trailing, 10)
                        .frame(width: geo.size.width * 0.3)
                        .onChange(of: backgroundId, {
                            self.banner?.updateBackgroundId(backgroundId)
                        })
                    }.padding()
                }
            } else {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Text("选择一个Banner")
                        Spacer()
                    }
                    Spacer()
                }
            }
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
                "无会员"
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
