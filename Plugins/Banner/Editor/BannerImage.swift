import MagicCore
import OSLog
import SwiftUI

struct BannerImage: View, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MessageProvider

    @State var isEditingTitle = false

    @Binding var banner: BannerModel

    var image: Image { banner.getImage() }

    var body: some View {
        ZStack {
            if banner.inScreen {
                switch banner.getDevice() {
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
        .contextMenu(menuItems: {
            Button("显示/隐藏边框") {
                banner.inScreen.toggle()
            }

            // MARK: Change Image

            Button("换图") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false

                if panel.runModal() == .OK, let url = panel.url {
                    os_log("\(self.t)Change Image -> \(url.relativeString)")

                    do {
                        try self.banner.changeImage(url)
                    } catch let e {
                        os_log(.error, "Error changing image: \(e)")
                        m.setError(e)
                    }
                }
            }
        })
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
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
