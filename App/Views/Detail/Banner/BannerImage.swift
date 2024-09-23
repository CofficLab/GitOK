import SwiftUI

struct BannerImage: View {
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

#Preview("App") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
