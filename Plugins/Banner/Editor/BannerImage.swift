import MagicCore
import OSLog
import SwiftUI

struct BannerImage: View, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State var isEditingTitle = false

    @Binding var banner: BannerData

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
                        m.error(e.localizedDescription)
                    }
                }
            }
        })
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
