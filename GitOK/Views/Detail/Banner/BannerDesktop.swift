import SwiftUI

struct BannerDesktop: View {
    @State var isEditingTitle = false
    @State var isEditingSubTitle = false

    @Binding var banner: BannerModel

    var device: Device { banner.getDevice() }
    var image: Image { banner.getImage() }

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 0, content: {
                getTitle().frame(height: device.height / 3)
                getBadges()
                Spacer()
            })
            .background(.red.opacity(0.0)).frame(width: device.width / 3)

            getContent()
                .padding(.trailing, 100)
                .frame(width: device.width / 3 * 2)
                .background(.green.opacity(0.0))
        }
        .onTapGesture {
            self.isEditingTitle = false
        }
        .background(BackgroundView.all[banner.backgroundId])
    }

    // MARK: 主标题与副标题

    private func getTitle() -> some View {
        VStack {
            if isEditingTitle {
                GeometryReader { geo in
                    TextField("e", text: $banner.title)
                        .font(.system(size: 200))
                        .padding(.horizontal)
                        .frame(width: geo.size.width)
                        .onSubmit {
                            self.isEditingTitle = false
                        }
                }
            } else {
                Text(banner.title)
                    .font(.system(size: 200))
                    .onTapGesture {
                        self.isEditingTitle = true
                    }
            }

            if isEditingSubTitle {
                GeometryReader { geo in
                    TextField("副标题", text: $banner.subTitle)
                        .font(.system(size: 100))
                        .padding(.horizontal)
                        .frame(width: geo.size.width)
                        .onSubmit {
                            self.isEditingSubTitle = false
                        }
                }
            } else {
                Text(banner.subTitle.isEmpty ? "副标题" : banner.subTitle)
                    .font(.system(size: 100))
                    .onTapGesture {
                        self.isEditingSubTitle = true
                    }
            }
        }
    }

    // MARK: 描述特性的小块

    private func getBadges() -> some View {
        Features(features: $banner.features)
    }

    // MARK: 右侧的视图

    private func getContent() -> some View {
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
                    ScreeniMac(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPhoneSmall:
                    ScreeniMac(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPad:
                    ScreeniMac(content: {
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
                    let ext = url.pathExtension
                    let storeURL = AppConfig.imagesDir.appendingPathComponent("\(TimeHelper.getTimeString()).\(ext)")
                    do {
                        try FileManager.default.copyItem(at: url, to: storeURL)
                        self.banner.imageURL = storeURL
                    } catch let e {
                        print(e)
                    }
                }
            }
        })
    }
}

#Preview("Banner-iMac") {
    @State var banner = BannerModel(
        title: "你好",
        subTitle: "xxxx",
        features: [
            "1",
            "2",
            "3",
            "4",
        ],
        backgroundId: "1",
        path: "E"
    )

    return RootView {
        GeometryReader { geo in
            BannerDesktop(banner: $banner)
                .frame(width: geo.size.width)
                .frame(height: geo.size.height)
                .alignmentGuide(HorizontalAlignment.center) { _ in geo.size.width / 2 }
                .alignmentGuide(VerticalAlignment.center) { _ in geo.size.height / 2 }
                .scaleEffect(min(geo.size.width / Device.iMac.width, geo.size.height / Device.iMac.height))
        }
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
