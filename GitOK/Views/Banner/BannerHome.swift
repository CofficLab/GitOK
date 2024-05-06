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
                    BannerBar(snapshotTapped: $snapshotTapped, banner: $banner)
                    
                    HStack {
                        BannerMaker(
                            snapshotTapped: $snapshotTapped,
                            onMessage: { message in
                                print("set message")
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
                            BannerFields(banner: $banner)

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
            }
        }
    }
}

#Preview("APP") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
